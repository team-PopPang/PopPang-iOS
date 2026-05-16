import csv
import re
from pathlib import Path

# ===== 설정 =====
SCRIPT_DIR = Path(__file__).resolve().parent
LANGUAGES = ["en", "ko", "ja"]

CSV_PATH = SCRIPT_DIR / "localizable.csv"
if not CSV_PATH.exists():
    raise FileNotFoundError(f"CSV file not found: {CSV_PATH.name}")

OUTPUT_BASE_DIR = SCRIPT_DIR / "android_output"
OUTPUT_DIRS = {
    "en": OUTPUT_BASE_DIR / "values",
    "ko": OUTPUT_BASE_DIR / "values-ko",
    "ja": OUTPUT_BASE_DIR / "values-ja",
}
OUTPUT_FILES = {
    lang: OUTPUT_DIRS[lang] / "strings.xml"
    for lang in LANGUAGES
}


def to_android_resource_name(key: str) -> str:
    resource_name = key.strip().lower()
    resource_name = re.sub(r"[^a-z0-9_]", "_", resource_name.replace(".", "_").replace("-", "_"))
    resource_name = re.sub(r"_+", "_", resource_name).strip("_")

    if not resource_name:
        raise ValueError(f"Invalid localization key: {key}")

    if resource_name[0].isdigit():
        resource_name = f"key_{resource_name}"

    return resource_name


def escape_android_string(value: str) -> str:
    escaped = value.replace("&", "&amp;").replace("<", "&lt;").replace(">", "&gt;")
    escaped = escaped.replace("'", "\\'")
    escaped = escaped.replace('"', '\\"')
    escaped = escaped.replace("\n", "\\n")
    escaped = escaped.replace("@", "\\@") if escaped.startswith("@") else escaped
    escaped = escaped.replace("?", "\\?") if escaped.startswith("?") else escaped
    return escaped


for lang in LANGUAGES:
    OUTPUT_DIRS[lang].mkdir(parents=True, exist_ok=True)


localizations = {lang: [] for lang in LANGUAGES}
seen_resource_names: dict[str, str] = {}

with CSV_PATH.open("r", encoding="utf-8") as file:
    reader = csv.DictReader(file)

    for row in reader:
        key = row["key"].strip()
        resource_name = to_android_resource_name(key)

        existing_key = seen_resource_names.get(resource_name)
        if existing_key and existing_key != key:
            raise ValueError(
                f"Duplicate Android resource name detected: '{key}' and '{existing_key}' -> '{resource_name}'"
            )
        seen_resource_names[resource_name] = key

        for lang in LANGUAGES:
            value = escape_android_string(row[lang])
            localizations[lang].append(f'    <string name="{resource_name}">{value}</string>')


for lang in LANGUAGES:
    content = ['<?xml version="1.0" encoding="utf-8"?>', "<resources>"]
    content.extend(localizations[lang])
    content.append("</resources>")

    with OUTPUT_FILES[lang].open("w", encoding="utf-8") as file:
        file.write("\n".join(content) + "\n")


print(f"✅ Android localization files generated successfully! CSV: {CSV_PATH.name}")
for lang in LANGUAGES:
    print(f" - {OUTPUT_FILES[lang]}")
