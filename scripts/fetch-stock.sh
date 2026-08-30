#!/usr/bin/env bash
# Regenerate vendor/compact-bar-stock from the upstream zellij v0.45.0 release.
#
# This fetches the pristine, unmodified compact-bar plugin source so you can diff it
# against our customized src/:
#   diff -r vendor/compact-bar-stock/src src/
#
# Usage: scripts/fetch-stock.sh [TAG]
set -euo pipefail

TAG="${1:-v0.45.0}"
DEST="$(cd "$(dirname "$0")/.." && pwd)/vendor/compact-bar-stock"

TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT

git clone --depth 1 --branch "$TAG" https://github.com/zellij-org/zellij.git "$TMP/zellij"

SRC="$TMP/zellij/default-plugins/compact-bar/src"
if [[ ! -d "$SRC" ]]; then
    echo "error: no default-plugins/compact-bar in $TAG" >&2
    exit 1
fi

mkdir -p "$DEST/src"
cp "$SRC"/*.rs "$DEST/src/"

echo "updated $DEST from zellij $TAG (src/*.rs)"