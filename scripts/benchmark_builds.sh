#!/usr/bin/env bash
#
# PopPang 빌드 벤치마크 스크립트
#
# 목적:
#   V0 단일 프로젝트와 Tuist 모듈화 프로젝트의 clean build / incremental build 시간을
#   같은 조건에서 반복 측정하고 CSV와 로그로 남긴다.
#
# 기본 동작:
#   1. tuist generate 시간을 측정한다.
#   2. V0 clean build 시간을 측정한다.
#   3. V0 incremental build 시간을 측정한다.
#   4. 모듈화 clean build 시간을 측정한다.
#   5. 모듈화 incremental build 시간을 측정한다.
#
# 사용법:
#   ./scripts/benchmark_builds.sh [options]
#
# 자주 쓰는 예시:
#   ./scripts/benchmark_builds.sh
#   ./scripts/benchmark_builds.sh --repeat 5
#   ./scripts/benchmark_builds.sh --skip-generate
#   ./scripts/benchmark_builds.sh \
#     --repeat 5 \
#     --destination "platform=iOS Simulator,name=iPhone 16,OS=26.0"
#   ./scripts/benchmark_builds.sh \
#     --repeat 5 \
#     --destination "platform=iOS Simulator,id=04A21A16-9115-4403-94B7-75403195DD1F"
#   ./scripts/benchmark_builds.sh \
#     --repeat 5 \
#     --v0-touch-file V0/PopPang/Sources/Presentation/MainTab/Tabs/Home/HomeView.swift \
#     --modular-touch-file Projects/Features/HomeFeature/Sources/Presentation/HomeView.swift
#
# 참고:
#   기본 destination인 "generic/platform=iOS Simulator"는 arm64/x86_64 시뮬레이터 산출물을
#   함께 만들 수 있다. Xcode에서 특정 시뮬레이터를 선택해 빌드한 체감 시간과 맞추려면
#   "platform=iOS Simulator,name=iPhone 16,OS=26.0"처럼 실제 시뮬레이터와 OS를 지정한다.
#   같은 이름의 시뮬레이터가 여러 OS에 있으면 OS 또는 id를 반드시 지정해야 한다.
#   id는 로컬 시뮬레이터마다 다르므로 xcrun simctl list devices available 출력에서 확인한다.
#
# 벤치마크 산출물 정리:
#   ./scripts/benchmark_clean.sh

set -euo pipefail

REPEAT=3
DESTINATION="generic/platform=iOS Simulator"
CONFIGURATION="Debug"
BASE_DIR="/tmp/poppang-build-benchmark"
RESULT_DIR=""
SKIP_GENERATE=false
V0_TOUCH_FILE=""
MODULAR_TOUCH_FILE=""
COOLDOWN_SECONDS=0

V0_PROJECT="V0/PopPang.xcodeproj"
V0_SCHEME="PopPang"
MODULAR_WORKSPACE="PopPang.xcworkspace"
MODULAR_SCHEME="PopPangApp"

usage() {
  cat <<'EOF'
사용법:
  ./scripts/benchmark_builds.sh [options]

옵션:
  --repeat N                  측정 반복 횟수. 기본값: 3
  --destination VALUE         xcodebuild destination 값. 기본값: generic/platform=iOS Simulator
  --configuration VALUE       빌드 configuration. 기본값: Debug
  --base-dir PATH             벤치마크 임시 디렉터리. 기본값: /tmp/poppang-build-benchmark
  --result-dir PATH           결과 저장 디렉터리. 기본값: $BASE_DIR/results/YYYYMMDD-HHMMSS
  --skip-generate             tuist generate 측정을 건너뛴다.
  --v0-touch-file PATH        V0 incremental build 전에 touch할 파일.
  --modular-touch-file PATH   모듈화 incremental build 전에 touch할 파일.
  --cooldown SECONDS          각 벤치마크 케이스 사이 대기 시간. 기본값: 0
  -h, --help                  도움말을 출력한다.

예시:
  ./scripts/benchmark_builds.sh --repeat 5

  ./scripts/benchmark_builds.sh \
    --repeat 5 \
    --destination "platform=iOS Simulator,name=iPhone 16,OS=26.0"

  또는 id로 더 정확히:

  ./scripts/benchmark_builds.sh \
    --repeat 5 \
    --destination "platform=iOS Simulator,id=04A21A16-9115-4403-94B7-75403195DD1F"

  ./scripts/benchmark_builds.sh \
    --repeat 5 \
    --v0-touch-file V0/PopPang/Sources/Presentation/MainTab/Tabs/Home/HomeView.swift \
    --modular-touch-file Projects/Features/HomeFeature/Sources/Presentation/HomeView.swift
EOF
}

now_seconds() {
  perl -MTime::HiRes=time -e 'printf "%.3f", time'
}

elapsed_seconds() {
  awk -v start="$1" -v end="$2" 'BEGIN { printf "%.3f", end - start }'
}

require_command() {
  if ! command -v "$1" >/dev/null 2>&1; then
    echo "필수 명령어를 찾을 수 없습니다: $1" >&2
    exit 1
  fi
}

csv_escape() {
  printf '%s' "$1" | sed 's/"/""/g; s/^/"/; s/$/"/'
}

append_csv() {
  local timestamp="$1"
  local run="$2"
  local case_name="$3"
  local target="$4"
  local mode="$5"
  local elapsed="$6"
  local status="$7"
  local log_file="$8"

  {
    csv_escape "$timestamp"; printf ','
    csv_escape "$run"; printf ','
    csv_escape "$case_name"; printf ','
    csv_escape "$target"; printf ','
    csv_escape "$mode"; printf ','
    csv_escape "$elapsed"; printf ','
    csv_escape "$status"; printf ','
    csv_escape "$log_file"; printf '\n'
  } >> "$CSV_FILE"
}

run_timed() {
  local run="$1"
  local case_name="$2"
  local target="$3"
  local mode="$4"
  local log_file="$5"
  shift 5

  echo "[$run] $case_name"
  echo "Command: $*" > "$log_file"
  echo "" >> "$log_file"

  local start
  local end
  local elapsed
  local status

  start="$(now_seconds)"
  set +e
  "$@" >> "$log_file" 2>&1
  status="$?"
  set -e
  end="$(now_seconds)"
  elapsed="$(elapsed_seconds "$start" "$end")"

  append_csv "$(date '+%Y-%m-%d %H:%M:%S')" "$run" "$case_name" "$target" "$mode" "$elapsed" "$status" "$log_file"

  echo "  elapsed=${elapsed}s status=${status} log=${log_file}"

  if [ "$status" -ne 0 ]; then
    echo ""
    echo "빌드 명령이 실패했습니다. 마지막 로그:"
    tail -n 80 "$log_file" || true
    exit "$status"
  fi

  if [ "$COOLDOWN_SECONDS" != "0" ]; then
    sleep "$COOLDOWN_SECONDS"
  fi
}

touch_if_needed() {
  local file="$1"

  if [ -z "$file" ]; then
    return 0
  fi

  if [ ! -f "$file" ]; then
    echo "touch 대상 파일이 없습니다: $file" >&2
    exit 1
  fi

  touch "$file"
}

while [ "$#" -gt 0 ]; do
  case "$1" in
    --repeat)
      REPEAT="$2"
      shift 2
      ;;
    --destination)
      DESTINATION="$2"
      shift 2
      ;;
    --configuration)
      CONFIGURATION="$2"
      shift 2
      ;;
    --base-dir)
      BASE_DIR="$2"
      shift 2
      ;;
    --result-dir)
      RESULT_DIR="$2"
      shift 2
      ;;
    --skip-generate)
      SKIP_GENERATE=true
      shift
      ;;
    --v0-touch-file)
      V0_TOUCH_FILE="$2"
      shift 2
      ;;
    --modular-touch-file)
      MODULAR_TOUCH_FILE="$2"
      shift 2
      ;;
    --cooldown)
      COOLDOWN_SECONDS="$2"
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

if ! [[ "$REPEAT" =~ ^[0-9]+$ ]] || [ "$REPEAT" -lt 1 ]; then
  echo "--repeat 값은 양의 정수여야 합니다." >&2
  exit 1
fi

require_command xcodebuild
require_command perl
require_command awk

if [ "$SKIP_GENERATE" = false ]; then
  require_command tuist
fi

if [ ! -d "$V0_PROJECT" ]; then
  echo "V0 프로젝트를 찾을 수 없습니다: $V0_PROJECT" >&2
  exit 1
fi

if [ -z "$RESULT_DIR" ]; then
  RESULT_DIR="$BASE_DIR/results/$(date '+%Y%m%d-%H%M%S')"
fi

LOG_DIR="$RESULT_DIR/logs"
CSV_FILE="$RESULT_DIR/results.csv"
V0_DERIVED_DATA="$BASE_DIR/derived-data/v0"
MODULAR_DERIVED_DATA="$BASE_DIR/derived-data/modular"

mkdir -p "$LOG_DIR"

{
  echo '"timestamp","run","case","target","mode","elapsed_seconds","status","log_file"'
} > "$CSV_FILE"

echo "빌드 벤치마크를 시작합니다."
echo "repeat=$REPEAT"
echo "destination=$DESTINATION"
echo "configuration=$CONFIGURATION"
echo "result_dir=$RESULT_DIR"
echo "csv=$CSV_FILE"
echo ""

for run in $(seq 1 "$REPEAT"); do
  echo "=== 실행 $run/$REPEAT ==="

  if [ "$SKIP_GENERATE" = false ]; then
    run_timed "$run" "tuist_generate" "Modular" "generate" "$LOG_DIR/${run}_tuist_generate.log" \
      tuist generate --no-open
  elif [ ! -d "$MODULAR_WORKSPACE" ]; then
    echo "모듈화 workspace가 없지만 --skip-generate가 지정되었습니다: $MODULAR_WORKSPACE" >&2
    exit 1
  fi

  rm -rf "$V0_DERIVED_DATA"
  run_timed "$run" "v0_clean" "V0" "clean" "$LOG_DIR/${run}_v0_clean.log" \
    xcodebuild \
      -project "$V0_PROJECT" \
      -scheme "$V0_SCHEME" \
      -configuration "$CONFIGURATION" \
      -destination "$DESTINATION" \
      -derivedDataPath "$V0_DERIVED_DATA" \
      COMPILER_INDEX_STORE_ENABLE=NO \
      clean build \
      -showBuildTimingSummary

  touch_if_needed "$V0_TOUCH_FILE"
  run_timed "$run" "v0_incremental" "V0" "incremental" "$LOG_DIR/${run}_v0_incremental.log" \
    xcodebuild \
      -project "$V0_PROJECT" \
      -scheme "$V0_SCHEME" \
      -configuration "$CONFIGURATION" \
      -destination "$DESTINATION" \
      -derivedDataPath "$V0_DERIVED_DATA" \
      COMPILER_INDEX_STORE_ENABLE=NO \
      build \
      -showBuildTimingSummary

  rm -rf "$MODULAR_DERIVED_DATA"
  run_timed "$run" "modular_clean" "Modular" "clean" "$LOG_DIR/${run}_modular_clean.log" \
    xcodebuild \
      -workspace "$MODULAR_WORKSPACE" \
      -scheme "$MODULAR_SCHEME" \
      -configuration "$CONFIGURATION" \
      -destination "$DESTINATION" \
      -derivedDataPath "$MODULAR_DERIVED_DATA" \
      COMPILER_INDEX_STORE_ENABLE=NO \
      clean build \
      -showBuildTimingSummary

  touch_if_needed "$MODULAR_TOUCH_FILE"
  run_timed "$run" "modular_incremental" "Modular" "incremental" "$LOG_DIR/${run}_modular_incremental.log" \
    xcodebuild \
      -workspace "$MODULAR_WORKSPACE" \
      -scheme "$MODULAR_SCHEME" \
      -configuration "$CONFIGURATION" \
      -destination "$DESTINATION" \
      -derivedDataPath "$MODULAR_DERIVED_DATA" \
      COMPILER_INDEX_STORE_ENABLE=NO \
      build \
      -showBuildTimingSummary

  echo ""
done

echo "요약:"
awk -F',' '
  NR > 1 {
    gsub(/^"|"$/, "", $3)
    gsub(/^"|"$/, "", $6)
    gsub(/^"|"$/, "", $7)
    if ($7 == "0") {
      sum[$3] += $6
      count[$3] += 1
    }
  }
  END {
    for (case_name in sum) {
      printf "  %-22s avg %.3fs (%d runs)\n", case_name, sum[case_name] / count[case_name], count[case_name]
    }
  }
' "$CSV_FILE" | sort

echo ""
echo "CSV: $CSV_FILE"
echo "Logs: $LOG_DIR"
