#!/usr/bin/env bash
#
# PopPang 빌드 벤치마크 정리 스크립트
#
# 목적:
#   benchmark_builds.sh 실행 전후에 V0와 Tuist 모듈화 프로젝트의 벤치마크용
#   DerivedData, build 산출물, SPM/Xcode 패키지 캐시, Tuist 캐시를 정리한다.
#
# 기본 동작:
#   1. V0 벤치마크 DerivedData를 삭제한다.
#   2. 모듈화 벤치마크 DerivedData와 로컬 build 산출물을 삭제한다.
#   3. SwiftPM/Xcode 패키지 캐시를 삭제해 다음 빌드에서 라이브러리를 다시 받게 만든다.
#   4. Tuist 캐시를 정리한다.
#   5. --xcodebuild-clean 옵션이 있으면 xcodebuild clean도 실행한다.
#
# 사용법:
#   ./scripts/benchmark_clean.sh
#   ./scripts/benchmark_clean.sh --v0-only
#   ./scripts/benchmark_clean.sh --modular-only
#   ./scripts/benchmark_clean.sh --artifacts-only
#   ./scripts/benchmark_clean.sh --xcodebuild-clean

set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

BASE_DIR="/tmp/poppang-build-benchmark"
CONFIGURATION="Debug"
DESTINATION="generic/platform=iOS Simulator"
CLEAN_V0=true
CLEAN_MODULAR=true
CLEAN_LIBRARY_CACHES=true
RUN_XCODEBUILD_CLEAN=false

V0_PROJECT="V0/PopPang.xcodeproj"
V0_SCHEME="PopPang"
MODULAR_WORKSPACE="PopPang.xcworkspace"
MODULAR_SCHEME="PopPangApp"

usage() {
  cat <<'EOF'
사용법:
  ./scripts/benchmark_clean.sh [options]

옵션:
  --v0-only               V0 프로젝트별 벤치마크 산출물만 정리한다. 공유 라이브러리 캐시는 기본으로 함께 삭제한다.
  --modular-only          모듈화 프로젝트별 벤치마크 산출물만 정리한다. 공유 라이브러리 캐시는 기본으로 함께 삭제한다.
  --artifacts-only        라이브러리 캐시는 남기고 DerivedData/build 산출물만 삭제한다.
  --xcodebuild-clean      산출물 삭제 후 xcodebuild clean도 실행한다. SPM resolve가 발생할 수 있다.
  --configuration VALUE   빌드 configuration. 기본값: Debug
  --destination VALUE     xcodebuild destination 값. 기본값: generic/platform=iOS Simulator
  --base-dir PATH         벤치마크 임시 디렉터리. 기본값: /tmp/poppang-build-benchmark
  -h, --help              도움말을 출력한다.

예시:
  ./scripts/benchmark_clean.sh
  ./scripts/benchmark_clean.sh --v0-only
  ./scripts/benchmark_clean.sh --modular-only
  ./scripts/benchmark_clean.sh --artifacts-only
  ./scripts/benchmark_clean.sh --xcodebuild-clean
EOF
}

require_command() {
  if ! command -v "$1" >/dev/null 2>&1; then
    echo "필수 명령어를 찾을 수 없습니다: $1" >&2
    exit 1
  fi
}

remove_if_exists() {
  local path="$1"

  if [ -e "$path" ]; then
    echo "삭제: $path"
    rm -rf "$path"
  fi
}

while [ "$#" -gt 0 ]; do
  case "$1" in
    --v0-only)
      CLEAN_V0=true
      CLEAN_MODULAR=false
      shift
      ;;
    --modular-only)
      CLEAN_V0=false
      CLEAN_MODULAR=true
      shift
      ;;
    --artifacts-only)
      CLEAN_LIBRARY_CACHES=false
      shift
      ;;
    --xcodebuild-clean)
      RUN_XCODEBUILD_CLEAN=true
      shift
      ;;
    --configuration)
      CONFIGURATION="$2"
      shift 2
      ;;
    --destination)
      DESTINATION="$2"
      shift 2
      ;;
    --base-dir)
      BASE_DIR="$2"
      shift 2
      ;;
    -h|--help)
      usage
      exit 0
      ;;
    *)
      echo "알 수 없는 옵션입니다: $1" >&2
      usage
      exit 1
      ;;
  esac
done

if [ "$RUN_XCODEBUILD_CLEAN" = true ]; then
  require_command xcodebuild
fi

cd "$ROOT_DIR"

echo "벤치마크 정리를 시작합니다."
echo "configuration=$CONFIGURATION"
echo "destination=$DESTINATION"
echo "base_dir=$BASE_DIR"
echo "library_caches=$CLEAN_LIBRARY_CACHES"
echo "xcodebuild_clean=$RUN_XCODEBUILD_CLEAN"
echo ""

if [ "$CLEAN_V0" = true ]; then
  if [ "$RUN_XCODEBUILD_CLEAN" = true ] && [ ! -d "$V0_PROJECT" ]; then
    echo "V0 프로젝트를 찾을 수 없습니다: $V0_PROJECT" >&2
    exit 1
  fi

  echo "V0 벤치마크 산출물을 정리합니다..."
  remove_if_exists "$BASE_DIR/derived-data/v0"

  if [ "$RUN_XCODEBUILD_CLEAN" = true ]; then
    xcodebuild \
      -project "$V0_PROJECT" \
      -scheme "$V0_SCHEME" \
      -configuration "$CONFIGURATION" \
      -destination "$DESTINATION" \
      -derivedDataPath "$BASE_DIR/derived-data/v0" \
      COMPILER_INDEX_STORE_ENABLE=NO \
      clean
  fi
fi

if [ "$CLEAN_MODULAR" = true ]; then
  echo "모듈화 벤치마크 산출물을 정리합니다..."
  remove_if_exists "$BASE_DIR/derived-data/modular"
  remove_if_exists build
  rm -rf /tmp/poppang-*-dd
  find Projects -name 'Derived' -type d -prune -exec rm -rf {} +
  find Projects -name 'build' -type d -prune -exec rm -rf {} +
  find ~/Library/Developer/Xcode/DerivedData -maxdepth 1 -name 'PopPang-*' -type d -prune -exec rm -rf {} +

  if [ "$RUN_XCODEBUILD_CLEAN" = true ] && [ -d "$MODULAR_WORKSPACE" ]; then
    xcodebuild \
      -workspace "$MODULAR_WORKSPACE" \
      -scheme "$MODULAR_SCHEME" \
      -configuration "$CONFIGURATION" \
      -destination "$DESTINATION" \
      -derivedDataPath "$BASE_DIR/derived-data/modular" \
      COMPILER_INDEX_STORE_ENABLE=NO \
      clean
  elif [ "$RUN_XCODEBUILD_CLEAN" = true ]; then
    echo "모듈화 workspace가 없어 xcodebuild clean은 건너뜁니다: $MODULAR_WORKSPACE"
  fi
fi

if [ "$CLEAN_LIBRARY_CACHES" = true ]; then
  echo "라이브러리/패키지 캐시를 정리합니다..."
  remove_if_exists "$BASE_DIR/derived-data"
  remove_if_exists "$ROOT_DIR/.build"
  remove_if_exists "$ROOT_DIR/Tuist/.build"
  remove_if_exists "$HOME/Library/Caches/org.swift.swiftpm"
  remove_if_exists "$HOME/Library/org.swift.swiftpm"
  find "$HOME/Library/Developer/Xcode/DerivedData" -maxdepth 2 -name 'SourcePackages' -type d -prune -exec rm -rf {} + 2>/dev/null || true
  find "$HOME/Library/Developer/Xcode/DerivedData" -maxdepth 1 -name 'ModuleCache.noindex' -type d -prune -exec rm -rf {} + 2>/dev/null || true

  if command -v tuist >/dev/null 2>&1; then
    echo "Tuist 캐시를 정리합니다..."
    tuist clean
  else
    echo "tuist 명령어가 없어 Tuist clean은 건너뜁니다."
  fi
fi

echo ""
echo "벤치마크 정리가 완료되었습니다."
