#!/usr/bin/env bash
#
# Builds the Mattermore server binary.
#
# Usage: ./scripts/build-server.sh [output-path]
# Requires: git, go, node, npm.

set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
OUT="${1:-$ROOT/dist/mattermore-server}"
WORK="$ROOT/build/server"

# shellcheck source=../upstream.env
source "$ROOT/upstream.env"

echo "==> upstream $SERVER_TAG"
rm -rf "$WORK"; mkdir -p "$(dirname "$WORK")" "$(dirname "$OUT")"
git clone --quiet --depth 1 --branch "$SERVER_TAG" \
    https://github.com/mattermost/mattermost.git "$WORK"

for patch in "$ROOT"/patches/server/*.patch; do
    echo "    $(basename "$patch")"
    git -C "$WORK" apply "$patch"
done

# Upstream's own build does this and gitignores the result: the server module
# depends on server/public, and without a workspace Go resolves it to the
# published version, which lags the tree and fails to compile.
( cd "$WORK/server" && go work init . ./public )

( cd "$WORK/server" && go build -o "$OUT" ./cmd/mattermost )
echo "==> $OUT"
