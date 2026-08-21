#!/usr/bin/env bash
# Reproducer driver for https://github.com/envoyproxy/envoy/issues/46841
#
# By default it pulls the published patched image and runs it twice (guard OFF vs guard ON) plus
# an echo upstream, then POSTs a known body through each and reports what the upstream received.
#
# Usage:
#   ./run.sh                 # uses the published image (REPRO_IMAGE default in docker-compose.yml)
#   REPRO_IMAGE=... ./run.sh # use a specific published/local image tag
#   BUILD_LOCAL=1 ./run.sh   # build the image locally from your patched envoy binary instead
#     (with BUILD_LOCAL=1, point ENVOY_BIN=/path/to/envoy if it isn't auto-detected)
set -euo pipefail

cd "$(dirname "$0")"

DC="docker compose"
if ! docker compose version >/dev/null 2>&1; then DC="docker-compose"; fi

# --- optionally build the patched image locally ---------------------------------
if [[ -n "${BUILD_LOCAL:-}" ]]; then
  CANDIDATES=(
    "${ENVOY_BIN:-}"
    "../bazel-bin/source/exe/envoy-static"
  )
  BIN=""
  for c in "${CANDIDATES[@]}"; do
    if [[ -n "$c" && -f "$c" ]]; then BIN="$c"; break; fi
  done
  if [[ -z "$BIN" ]]; then
    echo "ERROR: BUILD_LOCAL set but no patched envoy binary found." >&2
    echo "Build it first, e.g.:" >&2
    echo "  ./ci/run_envoy_docker.sh './ci/do_ci.sh release.server_only'" >&2
    echo "then re-run, optionally with ENVOY_BIN=/path/to/envoy BUILD_LOCAL=1 ./run.sh" >&2
    exit 1
  fi
  echo ">> using patched binary: $BIN"
  cp -f "$BIN" ./envoy
  chmod +x ./envoy
  export REPRO_IMAGE="${REPRO_IMAGE:-envoy-patched:repro}"
  echo ">> building image $REPRO_IMAGE ..."
  docker build -t "$REPRO_IMAGE" .
fi

# --- bring the stack up ---------------------------------------------------------
echo ">> starting stack (image: ${REPRO_IMAGE:-published default})..."
$DC up -d

cleanup() { echo ">> tearing down..."; $DC down -v >/dev/null 2>&1 || true; }
trap cleanup EXIT

echo ">> waiting for Envoy admin endpoints..."
wait_ready() {
  local name="$1" port="$2"
  for _ in $(seq 1 30); do
    if [[ "$(curl -s -o /dev/null -w '%{http_code}' "http://localhost:${port}/ready" 2>/dev/null)" == "200" ]]; then
      echo "   $name (:$port) ready"
      return 0
    fi
    # If the container already died there's no point in waiting.
    if [[ "$($DC ps -q "$name" | xargs -r docker inspect -f '{{.State.Running}}' 2>/dev/null)" == "false" ]]; then
      break
    fi
    sleep 1
  done
  echo "ERROR: $name did not become ready. Container logs:" >&2
  $DC logs "$name" >&2 || true
  return 1
}

if ! wait_ready envoy-off 9901 || ! wait_ready envoy-on 9902; then
  echo "ERROR: at least one Envoy failed to start; aborting." >&2
  exit 1
fi

# --- drive traffic --------------------------------------------------------------
# The body is sent in two writes with a small gap so Envoy sees (at least) two body frames.
# The trigger filter drops the FIRST (non-final) frame; the second frame carries end_stream and
# completes the request. So: guard OFF -> upstream gets only PART_B; guard ON -> PART_A + PART_B.
PART_A="$(printf 'A%.0s' $(seq 1 1000))"   # 1000 'A's  -- the frame that gets dropped when buggy
PART_B="$(printf 'B%.0s' $(seq 1 1000))"   # 1000 'B's  -- always delivered (carries end_stream)
SENT_LEN=$(( ${#PART_A} + ${#PART_B} ))

probe() {
  local label="$1" port="$2"
  echo
  echo "=================================================================="
  echo " $label  (localhost:${port})"
  echo "=================================================================="
  local resp got_len
  # Send CHUNKED (curl -T - => no Content-Length) in two writes separated by a gap, so the codec
  # dispatches two separate body frames. Chunked also avoids a Content-Length/upstream deadlock.
  resp="$( { printf '%s' "$PART_A"; sleep 0.5; printf '%s' "$PART_B"; } \
             | curl -sS --max-time 20 -X POST -T - \
                 -H 'content-type: text/plain' "http://localhost:${port}/" \
             || echo '<curl failed/timed out>')"
  # mendhak/http-https-echo returns JSON; extract the reflected body.
  if command -v jq >/dev/null 2>&1; then
    got_len="$(printf '%s' "$resp" | jq -r '.body | tostring | length' 2>/dev/null || echo '?')"
  else
    got_len="(install jq for automatic length check)"
  fi
  echo "sent body length     : $SENT_LEN  (PART_A=${#PART_A} + PART_B=${#PART_B})"
  echo "upstream received len : $got_len"
  echo "--- raw echo response ---"
  printf '%s\n' "$resp"
}

probe "GUARD OFF (buggy)  -> expect upstream body == ${#PART_B} (PART_A dropped)" 10000
probe "GUARD ON  (fixed)  -> expect upstream body == $SENT_LEN" 10001

echo
echo ">> Done. Guard OFF should show a lost body; guard ON should show it intact."
