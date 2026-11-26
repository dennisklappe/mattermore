#!/usr/bin/env bash
#
# Builds the Mattermore Playbooks plugin bundle.
#
# Usage: ./scripts/build-playbooks.sh [output-dir]
# Requires: git, go, node, npm, make.

set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
OUT="${1:-$ROOT/dist}"
WORK="$ROOT/build/playbooks"

# shellcheck source=../upstream.env
source "$ROOT/upstream.env"

echo "==> upstream $PLAYBOOKS_TAG, mattermore $PLAYBOOKS_VERSION"
rm -rf "$WORK"; mkdir -p "$(dirname "$WORK")" "$OUT"
git clone --quiet --depth 1 --branch "$PLAYBOOKS_TAG" \
    https://github.com/mattermost/mattermost-plugin-playbooks.git "$WORK"

for patch in "$ROOT"/patches/playbooks/*.patch; do
    echo "    $(basename "$patch")"
    git -C "$WORK" apply "$patch"
done

# A fresh checkout does not compile until the manifest is generated.
make -C "$WORK" apply

# The Source Available enterprise package must not be in the binary. A bundle
# that carried it would redistribute code Mattermore does not ship.
if (cd "$WORK" && go list -deps ./server/) | grep -q 'mattermost-plugin-playbooks/server/enterprise'; then
    echo "the Source Available enterprise package is still compiled in" >&2
    exit 1
fi

# The plugin pins its Node version in .nvmrc. A newer npm rejects the plugin's
# lockfile, so a mismatch fails here, loudly, and not partway through npm ci.
want="$(tr -d '[:space:]v' < "$WORK/.nvmrc")"
have="$(node -v | tr -d 'v')"
case "$have" in
    "$want"|"$want".*) ;;
    *) echo "the plugin wants Node $want (.nvmrc) but this is Node $have" >&2; exit 1 ;;
esac

# The webapp is installed up front for the same reason the calls build does it.
( cd "$WORK/webapp" && npm ci --no-audit --no-fund )

make -C "$WORK" dist

# The version is stamped AFTER the build on purpose: `make dist` runs
# `manifest apply`, which rewrites plugin.json from `git describe --tags`.
bundle="$(find "$WORK/dist" -maxdepth 1 -name '*.tar.gz' -print -quit)"
[ -n "$bundle" ] || { echo "build produced no bundle" >&2; exit 1; }

stage="$(mktemp -d)"
tar xzf "$bundle" -C "$stage"
python3 "$ROOT/scripts/stamp-plugin.py" "$stage/playbooks/plugin.json" "$PLAYBOOKS_VERSION" "Playbooks (Mattermore)"

target="$OUT/mattermore-playbooks-$PLAYBOOKS_VERSION.tar.gz"
tar czf "$target" -C "$stage" playbooks
rm -rf "$stage"
( cd "$OUT" && sha256sum "$(basename "$target")" > "$(basename "$target").sha256" )

echo "==> $target"
