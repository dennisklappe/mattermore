#!/usr/bin/env bash
#
# Builds the Mattermore server image: upstream's Team Edition image with our
# binary and our calls plugin.
#
# Usage: ./scripts/build-image.sh [tag]
# Requires: podman or docker, plus whatever build-server.sh and build-calls.sh need.

set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
TAG="${1:-mattermore:dev}"
STAGE="$ROOT/build/image"

# shellcheck source=../upstream.env
source "$ROOT/upstream.env"

engine="$(command -v podman || command -v docker)" || {
    echo "needs podman or docker" >&2; exit 1
}

rm -rf "$STAGE"; mkdir -p "$STAGE"
"$ROOT/scripts/build-server.sh" "$STAGE/mattermore-server"
"$ROOT/scripts/build-calls.sh" "$STAGE"
mv "$STAGE/mattermore-calls-$CALLS_VERSION.tar.gz" "$STAGE/mattermore-calls.tar.gz"
cp "$ROOT/Containerfile" "$STAGE/Containerfile"

"$engine" build -t "$TAG" -f "$STAGE/Containerfile" "$STAGE"
echo "==> $TAG"
