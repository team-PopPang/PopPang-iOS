import csv
from pathlib import Path

# ===== 설정 =====
SCRIPT_DIR = Path(__file__).resolve().parent
PROJECT_ROOT = SCRIPT_DIR.parent
LANGUAGES = ["en", "ko", "ja"]

CSV_PATH = SCRIPT_DIR / "localizable.csv"
if not CSV_PATH.exists():
    raise FileNotFoundError(f"CSV file not found: {CSV_PATH.name}")

OUTPUT_DIR = PROJECT_ROOT / "PopPang" / "Resources"
OUTPUT_FILES = {
    lang: OUTPUT_DIR / f"{lang}.lproj" / "Localizable.strings"
    for lang in LANGUAGES
}
ENUM_OUTPUT_PATH = PROJECT_ROOT / "PopPang" / "Sources" / "Util" / "Constants" / "LocalizationKeys.swift"


def to_swift_case_name(key: str) -> str:
    separators_replaced = key.replace(".", "_").replace("-", "_")
    parts = [part for part in separators_replaced.split("_") if part]
    if not parts:
        raise ValueError(f"Invalid localization key: {key}")

    first = parts[0].lower()
    rest = [part[:1].upper() + part[1:] for part in parts[1:]]
    return first + "".join(rest)

# ====== 폴더 생성 ======
for lang in LANGUAGES:
    (OUTPUT_DIR / f"{lang}.lproj").mkdir(parents=True, exist_ok=True)

# ====== CSV 읽기 ======
localizations = {lang: [] for lang in LANGUAGES}
enum_keys = [
    "import Foundation\n\npublic enum LocalizationKey: String {"
]

with CSV_PATH.open("r", encoding="utf-8") as f:
    reader = csv.DictReader(f)

    for row in reader:
        key = row["key"]

        # enum 추가
        enum_keys.append(f"    case {to_swift_case_name(key)} = \"{key}\"")

        # 각 언어별 strings 생성
        for lang in LANGUAGES:
            value = row[lang]
            line = f"\"{key}\" = \"{value}\";"
            localizations[lang].append(line)

# ====== strings 파일 생성 ======
for lang in LANGUAGES:
    with OUTPUT_FILES[lang].open("w", encoding="utf-8") as f:
        f.write("\n".join(localizations[lang]))

# ====== enum 파일 생성 ======
enum_keys.append("}")
ENUM_OUTPUT_PATH.parent.mkdir(parents=True, exist_ok=True)

with ENUM_OUTPUT_PATH.open("w", encoding="utf-8") as f:
    f.write("\n".join(enum_keys))

print(f"✅ Localization files generated successfully! CSV: {CSV_PATH.name}")
