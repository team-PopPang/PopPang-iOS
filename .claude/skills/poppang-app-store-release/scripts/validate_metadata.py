#!/usr/bin/env python3
"""팝팡 App Store 출시 문구와 심사 노트의 형식을 검사한다."""

from __future__ import annotations

import argparse
import sys
from pathlib import Path


REVIEW_NOTES_PATH = Path("review_information/notes.txt")
KOREAN_LOGIN_HEADING = "[로그인 안내]"
KOREAN_UPDATE_HEADING = "[업데이트 내용 안내]"
ENGLISH_LOGIN_HEADING = "[Login Instructions]"
ENGLISH_UPDATE_HEADING = "[Update Information]"
REVIEW_HEADINGS = (
    KOREAN_LOGIN_HEADING,
    KOREAN_UPDATE_HEADING,
    ENGLISH_LOGIN_HEADING,
    ENGLISH_UPDATE_HEADING,
)
MAX_RELEASE_NOTE_BULLETS = 4


def read_text(path: Path, errors: list[str]) -> str:
    if not path.is_file():
        errors.append(f"파일이 없습니다: {path}")
        return ""

    try:
        text = path.read_text(encoding="utf-8")
    except UnicodeDecodeError:
        errors.append(f"UTF-8이 아닙니다: {path}")
        return ""

    if not text.strip():
        errors.append(f"내용이 비어 있습니다: {path}")
    elif not text.endswith("\n"):
        errors.append(f"마지막 줄바꿈이 없습니다: {path}")
    elif "TODO" in text.upper():
        errors.append(f"TODO가 남아 있습니다: {path}")
    return text


def release_note_bullets(path: Path, text: str, errors: list[str]) -> list[str]:
    lines = [line.rstrip() for line in text.splitlines() if line.strip()]
    if not lines:
        return []
    if not lines[0].startswith("■"):
        errors.append(f"첫 줄은 ■ 제목이어야 합니다: {path}")

    bullets = []
    for line in lines[1:]:
        if line.startswith("- "):
            bullets.append(line[2:].strip())
        else:
            errors.append(f"제목 아래 줄은 '- '로 시작해야 합니다: {path}: {line}")

    if not bullets:
        errors.append(f"'- ' 항목이 하나 이상 있어야 합니다: {path}")
    if len(bullets) > MAX_RELEASE_NOTE_BULLETS:
        errors.append(f"항목이 {MAX_RELEASE_NOTE_BULLETS}개보다 많습니다: {path}")
    return bullets


def section_bullets(text: str, heading: str) -> list[str]:
    """heading 줄부터 다음 [제목] 줄 전까지의 '- ' 항목을 돌려준다."""
    bullets: list[str] = []
    in_section = False
    for raw_line in text.splitlines():
        line = raw_line.strip()
        if line == heading:
            in_section = True
            continue
        if in_section and line.startswith("[") and line.endswith("]"):
            break
        if in_section and line.startswith("- "):
            bullets.append(line[2:].strip())
    return bullets


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument(
        "--metadata-root",
        type=Path,
        default=Path("fastlane/metadata"),
        help="fastlane 메타데이터 폴더 (기본값: fastlane/metadata)",
    )
    args = parser.parse_args()

    root = args.metadata_root
    errors: list[str] = []
    warnings: list[str] = []

    locales = sorted(path.parent.name for path in root.glob("*/release_notes.txt"))
    if "ko" not in locales:
        errors.append(f"한국어 출시 문구가 없습니다: {root / 'ko/release_notes.txt'}")

    bullets_by_locale: dict[str, list[str]] = {}
    for locale in locales:
        path = root / locale / "release_notes.txt"
        text = read_text(path, errors)
        bullets_by_locale[locale] = release_note_bullets(path, text, errors)

    korean_bullets = bullets_by_locale.get("ko", [])
    for locale, bullets in bullets_by_locale.items():
        if locale != "ko" and len(bullets) != len(korean_bullets):
            errors.append(
                f"{locale} 출시 문구의 항목 수({len(bullets)})가 한국어({len(korean_bullets)})와 다릅니다."
            )

    review_path = root / REVIEW_NOTES_PATH
    review_text = read_text(review_path, errors)
    for heading in REVIEW_HEADINGS:
        if heading not in review_text:
            errors.append(f"심사 노트에 {heading} 구역이 없습니다.")

    korean_update = section_bullets(review_text, KOREAN_UPDATE_HEADING)
    english_update = section_bullets(review_text, ENGLISH_UPDATE_HEADING)
    if not korean_update:
        errors.append(f"심사 노트의 {KOREAN_UPDATE_HEADING}에 '- ' 항목이 없습니다.")
    if not english_update:
        errors.append(f"심사 노트의 {ENGLISH_UPDATE_HEADING}에 '- ' 항목이 없습니다.")
    if korean_update and english_update and len(korean_update) != len(english_update):
        errors.append(
            f"심사 노트의 영어 항목 수({len(english_update)})가 한국어({len(korean_update)})와 다릅니다."
        )

    # 출시 문구의 농담 같은 항목은 심사 노트에 넣지 않으므로 오류가 아니라 확인용으로만 알린다.
    for bullet in korean_bullets:
        if bullet not in korean_update:
            warnings.append(f"한국어 출시 문구 항목이 심사 노트에 없습니다: {bullet}")

    for warning in warnings:
        print(f"확인: {warning}")

    if errors:
        print("메타데이터 검사에 실패했습니다:", file=sys.stderr)
        for error in errors:
            print(f"- {error}", file=sys.stderr)
        return 1

    print(f"메타데이터 검사를 통과했습니다: 출시 문구({', '.join(locales)}), 심사 노트")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
