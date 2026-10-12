---
name: poppang-app-store-release
description: 팝팡 iOS 앱의 App Store 출시를 준비하고 TestFlight에 올린다. 사용자가 "출시 준비해줘", "앱스토어 배포 준비", "TestFlight 올려줘", "릴리즈 노트 써줘", "새 버전 올려줘"처럼 요청할 때 쓴다. App Store 버전 확인, 필요하면 버전 올리기와 출시 PR, 머지된 PR로 출시 문구(ko·en-US)와 심사 노트(한글·영문) 작성, 스토어 문구 반영, fastlane beta 업로드까지 한다. 심사 제출은 하지 않는다.
---

# 팝팡 App Store 출시 준비

세팅 방법과 lane 설명은 [앱스토어 출시](../../../Docs/development/app-store-release.md)에 있다. 이 스킬은 그 순서대로 출시를 준비한다.

## 지킬 것

- 외부에 반영되는 일(이슈·PR 생성, 스토어 문구 반영, TestFlight 업로드)은 아래 확인 지점에서 사용자 승인을 받은 뒤에만 한다. 스킬을 실행했다고 모든 단계를 승인한 것으로 보지 않는다.
- `fastlane/.env`와 `fastlane/metadata/review_information/demo_user.txt`, `demo_password.txt`는 열거나 출력하지 않는다. API 키와 테스트 계정 값을 대화에 남기지 않는다.
- `fastlane/metadata/`와 `fastlane/screenshots/`는 git이 무시한다. 커밋하지 않고, 바뀐 내용은 파일을 다시 읽어서 확인한다.
- 심사 제출은 하지 않는다. `fastlane release`는 심사 제출까지 하므로 실행하지 않는다.
- 사용자에게는 한국어로 짧게 보고한다.

## fastlane 실행 방법

- `bundle check`가 통과하면 `bundle exec fastlane`을, 아니면 Homebrew로 설치한 `fastlane`을 쓴다. 둘 다 없으면 멈추고 세팅 문서를 안내한다.
- 명령 앞에 항상 `LC_ALL=en_US.UTF-8 LANG=en_US.UTF-8 FASTLANE_SKIP_UPDATE_CHECK=1`을 붙인다. 한글 파일을 읽을 때 인코딩 오류가 나지 않게 한다.
- 아래에서 `$FASTLANE`은 이렇게 고른 명령이다.

## 1. 시작 점검

1. `git branch --show-current`와 `git status --short`를 확인한다. 관련 없는 변경이 있으면 건드리지 않고 사용자에게 알린다.
2. `gh auth status`로 GitHub 로그인을 확인한다.
3. `git fetch origin` 뒤 지금 브랜치가 `origin/main`과 같은지 본다. 출시 빌드는 최신 `main`에서 만든다. 다르면 이유를 묻는다.

## 2. 버전 확인

`$FASTLANE release_status`를 실행한다. App Store Connect를 읽기만 한다. API 키가 없으면 lane이 `fastlane/.env`를 채우라는 메시지와 함께 멈추므로, 그 내용을 사용자에게 전한다.

출력의 `RELEASE_STATUS`에 따라 나눈다.

| 값 | 뜻 | 다음 단계 |
| --- | --- | --- |
| `READY` | 지금 버전으로 올릴 수 있다. | 3단계를 건너뛰고 4단계로 간다. |
| `BUMP_REQUIRED` | 지금 버전과 같거나 높은 버전이 이미 승인됐다. | 출시된 버전과 `SUGGESTED_VERSION`을 보여 주고 새 버전 번호를 받는다. |
| `IN_REVIEW` | 같은 버전이 심사 중이다. | 심사를 취소하고 같은 버전으로 다시 올릴지, 버전을 올릴지 묻는다. 심사 취소는 사용자가 App Store Connect에서 직접 한다. |

**확인 지점 1: 버전 번호.** 예: "1.1.7이 이미 출시돼서 버전을 올려야 해요. 1.1.8로 할까요?" 받은 번호는 `x.y.z` 형식이고 출시된 버전보다 높아야 한다.

## 3. 버전 올리기 (`BUMP_REQUIRED`일 때만)

[Git 작업 흐름](../../../Docs/development/gitflow.md)을 따른다.

1. 이슈 `[chore] {버전} 출시를 준비한다`를 라벨 `⚙️ chore`, `--assignee @me`로 만든다. 본문은 이슈 템플릿의 순서를 지킨다.
2. 자동으로 만들어진 `chore/#{이슈번호}` 브랜치를 받는다.
3. `Projects/App/Project.swift`의 `"MARKETING_VERSION"` 값만 새 버전으로 바꾼다.
4. 커밋 메시지는 `chore: 앱 버전을 {버전}로 올림`으로 쓰고, push한 뒤 PR을 만든다. PR 제목은 이슈 제목과 같게 쓰고, 본문은 PR 템플릿과 `.agents/skills/auto-pr/SKILL.md` 규칙을 따른다.
5. 빌드는 이 브랜치에서 올린다. PR 머지는 사용자가 한다.

## 4. 출시 범위 정하기

1. 마지막 출시 태그를 찾는다. `git describe --tags --abbrev=0 origin/main` 또는 `gh release list --limit 1`을 쓴다. 사용자가 범위를 주면 그 범위를 쓴다.
2. `git log {태그}..HEAD --oneline`에서 `(#번호)`로 머지된 PR을 찾고, `gh pr view {번호} --json title,body,labels,files`로 내용을 읽는다.
3. diff를 확인하고 사용자에게 보이는 변경만 고른다.
   - 넣는 것: 새 기능, 화면·사용성 개선, 사용자가 겪던 문제의 수정
   - 빼는 것: 리팩터링, CI, 문서, 테스트, 의존성, 관리자 전용 기능, 내부 구조 변경
   - PR 제목만 보고 내용을 지어내지 않는다.

**확인 지점 2: 출시 범위.** 넣을 변경과 뺀 변경을 PR 번호와 함께 보여 주고 확인받는다.

## 5. 스토어 문구 내려받기

`$FASTLANE download_store_metadata`로 지금 스토어 문구를 받는다. App Store Connect는 바꾸지 않는다. 받은 뒤 `fastlane/metadata/*/release_notes.txt`로 언어 목록을 확인한다(2026-10 기준 `ko`, `en-US`).

## 6. 출시 문구 쓰기

지금 파일의 형식과 말투를 그대로 따른다.

- 첫 줄은 `■ {분류}`다. 예: `■ 새로운 기능`, `■ 기능 개선`, `■ 버그 수정`
- 그 아래에 `- ` 항목을 1~4개 둔다.
- 한국어(`ko/release_notes.txt`)를 먼저 쓴다. 문장은 지금 문구처럼 `~했습니다`로 끝낸다.
- `en-US/release_notes.txt`는 확정한 한국어의 뜻을 자연스러운 영어로 옮긴다. 과거형(`Added`, `Improved`, `Fixed`)으로 쓴다.
- 다른 언어 폴더가 있으면 그 언어로도 옮긴다. 항목 수는 모든 언어에서 같게 한다.
- PR 번호, 브랜치, 모듈 이름, 내부 구조, 근거 없는 주장("안정성이 향상되었습니다" 등)은 쓰지 않는다.
- 지금 문구처럼 가벼운 농담 한 줄을 넣을지는 사용자에게 묻는다. 넣으면 마지막 항목으로 두고, 심사 노트에는 넣지 않는다.

## 7. 심사 노트 쓰기

`fastlane/metadata/review_information/notes.txt`의 네 구역을 유지한다: `[로그인 안내]`, `[업데이트 내용 안내]`, `[Login Instructions]`, `[Update Information]`.

1. `[로그인 안내]`와 `[Login Instructions]`는 그대로 둔다. 로그인 방식이나 연락처가 바뀌었을 때만 사용자에게 내용을 받아 고친다. 테스트 계정 정보를 지어내지 않는다.
2. `[업데이트 내용 안내]`에서는 `- ` 항목만 이번 변경으로 바꾼다. 출시 문구의 사실 항목을 쓰고, 심사에 도움이 되면 조금 더 자세히 쓴다.
3. `[Update Information]`의 항목은 위 한국어 항목과 같은 수, 같은 뜻의 영어로 쓴다.
4. 인사말, 맺음말, `팝팡팀 드림`, `The PopPang Team`은 그대로 둔다.

## 8. 검사와 확인

1. 검사 스크립트를 실행한다.

   ```bash
   python3 .claude/skills/poppang-app-store-release/scripts/validate_metadata.py --metadata-root fastlane/metadata
   ```

2. 바꾼 파일을 다시 읽는다. `확인:`으로 나온 항목은 의도한 것인지 본다(예: 심사 노트에 넣지 않은 농담 항목).

**확인 지점 3: 최종 문구.** ko·en-US 출시 문구와 심사 노트의 업데이트 구역을 그대로 보여 주고 승인을 받는다.

## 9. 스토어 문구 반영

`$FASTLANE upload_store_metadata version:{버전}`을 실행한다.

- 출시 문구, 심사 노트 등 내려받은 메타데이터를 App Store Connect에 올린다. 해당 버전이 없으면 새로 만들어진다.
- 스크린샷은 올리지 않는다. 사용자가 스크린샷을 바꿔 달라고 했을 때만 `screenshots:true`를 붙인다.
- 빌드 업로드와 심사 제출은 하지 않는다.

## 10. TestFlight 업로드

1. `$FASTLANE beta`를 백그라운드로 실행한다. 10분 안팎 걸린다. 빌드 번호는 TestFlight에 있는 같은 버전의 마지막 번호에 1을 더해 정해진다.
2. match 암호를 물으면 사용자가 직접 입력하도록 안내한다.
3. 실패하면 `~/Library/Logs/gym/PopPangApp-PopPangApp.log` 끝부분에서 원인을 찾아 보고하고 멈춘다. 같은 명령을 그냥 다시 실행하지 않는다.

## 11. 보고

- 버전과 빌드 번호, 반영한 출시 문구(ko·en-US), 심사 노트 업데이트 구역, 만든 이슈와 PR 링크를 정리한다.
- 남은 일을 알린다.
  - App Store Connect에서 빌드를 고르고 심사를 제출하는 일은 사람이 한다.
  - 출시한 뒤 GitHub Actions의 `Release with Notes` workflow(`.github/workflows/5. release.yml`)를 버전 번호로 실행해 `v{버전}` 태그와 GitHub 릴리스를 만든다. 다음 출시 범위의 기준이 된다.
- `fastlane/metadata/`는 git에 올라가지 않는다는 점도 함께 알린다.
