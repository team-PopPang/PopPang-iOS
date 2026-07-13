#!/usr/bin/env bash

set -euo pipefail

VERSION="${1:-v0.1.0}"
REPO="team-PopPang/PopPang-RN"
BUNDLE_ASSET_NAME="poppang-rn-ios-bundle-$VERSION.zip"
FRAMEWORK_ASSET_NAME="poppang-rn-spm-$VERSION.zip"
ROOT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
BUNDLE_OUTPUT_DIR="$ROOT_DIR/Projects/App/Resources/ReactNative"
FRAMEWORK_OUTPUT_DIR="$ROOT_DIR/Vendor/PrebuiltReactNativeFrameworks"
TMP_DIR="$ROOT_DIR/.rn-release-temp"

cleanup() {
    rm -rf "$TMP_DIR"
}

trap cleanup EXIT

echo "RN iOS 릴리즈 다운로드 시작: $VERSION"
rm -rf "$TMP_DIR"
mkdir -p "$TMP_DIR"

echo "iOS bundle 다운로드"
gh release download "$VERSION" \
    --repo "$REPO" \
    --pattern "$BUNDLE_ASSET_NAME" \
    --dir "$TMP_DIR" \
    --clobber

echo "SPM 패키지 다운로드"
gh release download "$VERSION" \
    --repo "$REPO" \
    --pattern "$FRAMEWORK_ASSET_NAME" \
    --dir "$TMP_DIR" \
    --clobber

echo "iOS bundle 압축 해제"
mkdir -p "$TMP_DIR/bundle"
unzip -o "$TMP_DIR/$BUNDLE_ASSET_NAME" -d "$TMP_DIR/bundle" >/dev/null

echo "SPM 패키지 압축 해제"
mkdir -p "$TMP_DIR/frameworks"
unzip -o "$TMP_DIR/$FRAMEWORK_ASSET_NAME" -d "$TMP_DIR/frameworks" >/dev/null

if [[ ! -f "$TMP_DIR/bundle/ios/main.jsbundle" ]]; then
    echo "main.jsbundle을 찾을 수 없습니다." >&2
    exit 1
fi

if [[ ! -f "$TMP_DIR/frameworks/PrebuiltReactNativeFrameworks/Package.swift" ]]; then
    echo "PrebuiltReactNativeFrameworks/Package.swift를 찾을 수 없습니다." >&2
    exit 1
fi

echo "iOS bundle 적용"
rm -rf "$BUNDLE_OUTPUT_DIR"
mkdir -p "$BUNDLE_OUTPUT_DIR"
cp "$TMP_DIR/bundle/ios/main.jsbundle" "$BUNDLE_OUTPUT_DIR/main.jsbundle"
if [[ -d "$TMP_DIR/bundle/ios/assets" ]]; then
    cp -R "$TMP_DIR/bundle/ios/assets" "$BUNDLE_OUTPUT_DIR/assets"
fi

echo "SPM 패키지 적용"
rm -rf "$FRAMEWORK_OUTPUT_DIR"
mkdir -p "$(dirname "$FRAMEWORK_OUTPUT_DIR")"
ditto \
    "$TMP_DIR/frameworks/PrebuiltReactNativeFrameworks" \
    "$FRAMEWORK_OUTPUT_DIR"

echo "다운로드 및 적용 완료"
echo "번들 위치: $BUNDLE_OUTPUT_DIR"
echo "프레임워크 위치: $FRAMEWORK_OUTPUT_DIR"
