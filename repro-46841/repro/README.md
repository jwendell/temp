# Reproducer: filter manager drops a body frame on continue (#46841)

This directory is a standalone Docker Compose reproducer for
[envoyproxy/envoy#46841](https://github.com/envoyproxy/envoy/issues/46841). It is **not**
part of the fix PR (#46842) and must not be upstreamed.

By default it uses the published image `quay.io/jwendell/envoy:reproducer-46841`, so you can run
it without building anything. Building locally is optional (see [Building locally](#building-locally)).

## What it demonstrates

The bug lives in `source/common/http/filter_manager.cc`: when a filter that is already
iterating drains the current body frame into the filter-manager buffer via
`addDecodedData()` / `addEncodedData()` and returns `Continue`, the manager forwards the
now-empty frame instead of the buffered bytes — so a body frame is silently dropped.

The reproducer wires a tiny purpose-built HTTP filter,
`envoy.filters.http.drain_and_continue` (compiled into your patched binary from
`source/extensions/filters/http/drain_and_continue/`), ahead of the router. On the first
**non-final** request body frame it does exactly the buggy sequence: `addDecodedData(frame)` +
`Continue`. Because it never drops the frame carrying `end_stream`, the request still completes
normally — the body just arrives truncated, exactly like the real bug (a lost *middle* chunk).

The fix is gated behind the runtime guard
`envoy.reloadable_features.filter_manager_forward_added_data_on_continue` (default **on**).
The compose stack runs the **same** patched image twice, differing only in that flag:

| Instance   | Port    | Guard | Expected upstream body                |
|------------|---------|-------|---------------------------------------|
| `envoy-off`| `10000` | OFF   | **truncated** (first frame dropped)   |
| `envoy-on` | `10001` | ON    | **intact**                            |

`run.sh` sends the body in two writes (`AAAA…` then `BBBB…`) so the codec produces two frames.
With the guard OFF the upstream receives only the `BBBB…` part; with it ON it receives both.

An `echo` upstream (`mendhak/http-https-echo`) reflects the request body back so you can see
exactly what arrived.

> Note: both instances use the patched binary; the guard flag is what flips behavior. This
> makes the demo deterministic. (Toggling the guard OFF is equivalent to running an
> unpatched/released Envoy for this code path.)

## Prerequisites

Docker + Docker Compose. That's it — the default image is pulled from the registry.

## Run

```bash
cd repro
./run.sh
```

`run.sh` brings up the stack (pulling `quay.io/jwendell/envoy:reproducer-46841`), POSTs a known
body through both instances, and prints the sent length vs. what the upstream received. With guard
OFF the body is truncated; with guard ON it matches.

To use a different published/local tag:

```bash
REPRO_IMAGE=quay.io/you/envoy:my-tag ./run.sh
```

## Building locally

To build the image yourself from a patched Envoy binary (the fix + the reproducer filter):

1. Build the binary:

   ```bash
   ./ci/run_envoy_docker.sh './ci/do_ci.sh release.server_only'
   ```

   Output lands at `/tmp/envoy-docker-build/envoy/source/exe/envoy` (or under
   `$ENVOY_DOCKER_BUILD_DIR`); a `dev`/`debug.server_only` build works too.

2. Run with `BUILD_LOCAL=1` (auto-detects the binary, or point `ENVOY_BIN` at it):

   ```bash
   BUILD_LOCAL=1 ./run.sh
   # or: ENVOY_BIN=/path/to/envoy BUILD_LOCAL=1 ./run.sh
   ```

   This copies the binary into the build context, builds `envoy-patched:repro`, and uses it.

## Publishing

The image is just your patched binary layered onto the official Envoy image (see `Dockerfile`):

```bash
cp /tmp/envoy-docker-build/envoy/source/exe/envoy ./envoy   # or your build output path
docker build -t quay.io/you/envoy:reproducer-46841 .
docker push  quay.io/you/envoy:reproducer-46841
```

Then set `REPRO_IMAGE` (or edit the default in `docker-compose.yml`) to point at it.

## Manual poking

Send the body **chunked** (`-T -`, no `Content-Length`) in **two writes** so the codec produces
two frames — the filter drops the first (non-final) one; the second carries `end_stream`. A fixed
`Content-Length` would instead make the upstream block forever waiting for the missing bytes.

```bash
# guard OFF (buggy): upstream sees only "world" (the "hello" frame was dropped)
{ printf 'hello'; sleep 0.5; printf 'world'; } | curl -sS -X POST -T - localhost:10000/ | jq .body

# guard ON (fixed): upstream sees "helloworld"
{ printf 'hello'; sleep 0.5; printf 'world'; } | curl -sS -X POST -T - localhost:10001/ | jq .body
```

## Files

- `envoy-guard-off.yaml` / `envoy-guard-on.yaml` — identical configs, guard flag flipped.
- `Dockerfile` — drops a patched `envoy` binary onto `envoyproxy/envoy:dev` (used for publishing/local builds).
- `docker-compose.yml` — echo upstream + two patched-Envoy instances (image via `REPRO_IMAGE`, default `quay.io/jwendell/envoy:reproducer-46841`).
- `run.sh` — end-to-end driver (published image by default; `BUILD_LOCAL=1` to build).
