# Builds a patched-Envoy image by dropping a locally-built envoy-static binary on top
# of the official Envoy base image (which already ships the required runtime + entrypoint).
#
# Expects the binary at ./envoy in the build context (run.sh copies it there for you).
FROM envoyproxy/envoy:dev

COPY envoy /usr/local/bin/envoy
