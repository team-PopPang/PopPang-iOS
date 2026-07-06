#!/usr/bin/env bash
set -euo pipefail

REPO="team-PopPang/PopPang-Flutter"
ROOT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
VERSION_FILE="$ROOT_DIR/.flutter-module-version"
VENDOR_DIR="$ROOT_DIR/Vendor/PopPangFlutter"
TMP_DIR="$ROOT_DIR/.tmp/poppang-flutter"
VERSION="${1:-}"

if [[ -z "$VERSION" ]]; then
  VERSION="$(tr -d '[:space:]' < "$VERSION_FILE")"
fi

TAG="v${VERSION}"
ASSET_NAME="poppang-flutter-ios-v${VERSION}.zip"

mkdir -p "$TMP_DIR" "$VENDOR_DIR"

gh release download "$TAG" \
  --repo "$REPO" \
  --pattern "$ASSET_NAME" \
  --dir "$TMP_DIR" \
  --clobber

rm -rf "$VENDOR_DIR/FlutterNativeIntegration" "$VENDOR_DIR/Scripts"
unzip -oq "$TMP_DIR/$ASSET_NAME" -d "$VENDOR_DIR"

echo "done: $VENDOR_DIR"