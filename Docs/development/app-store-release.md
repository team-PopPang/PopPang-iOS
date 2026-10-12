# PopPang 앱스토어 출시

이 문서는 TestFlight 업로드, App Store 문구·스크린샷 관리, Claude 출시 준비 스킬을 쓰는 방법을 정리한다.

## 목차

- [준비](#준비)
- [lane](#lane)
- [스토어 문구와 스크린샷](#스토어-문구와-스크린샷)
- [빌드 번호](#빌드-번호)
- [Claude 출시 준비 스킬](#claude-출시-준비-스킬)
- [출시한 뒤](#출시한-뒤)

## 준비

| 항목 | 방법 |
| --- | --- |
| fastlane | Homebrew(`brew install fastlane`)로 설치한 `fastlane`이나, `bundle install` 뒤 `bundle exec fastlane`을 쓴다. `Gemfile.lock`은 fastlane 2.233.1을 고정한다. |
| App Store Connect API 키 | `fastlane/.env`에 아래 세 값을 넣는다. App Store Connect > 사용자 및 액세스 > 통합 > App Store Connect API에서 만든다. 역할은 앱 관리자(App Manager) 이상이어야 한다. `.p8` 파일은 키를 만들 때 한 번만 받을 수 있다. |
| 배포 인증서 | 처음 한 번 `fastlane match appstore --readonly`를 실행하고 match 암호를 입력한다. 암호는 키체인에 저장된다. |
| GitHub CLI | `gh auth login`. 출시 준비 스킬이 PR을 읽고 이슈와 PR을 만든다. |
| 터미널 언어 설정 | UTF-8이 아니면 명령 앞에 `LC_ALL=en_US.UTF-8 LANG=en_US.UTF-8`을 붙인다. 한글 파일을 읽을 때 오류가 난다. |

`fastlane/.env` 형식:

```bash
APP_STORE_CONNECT_API_KEY_ID=키ID
APP_STORE_CONNECT_API_KEY_ISSUER_ID=IssuerID
APP_STORE_CONNECT_API_KEY_CONTENT="-----BEGIN PRIVATE KEY-----
...키 내용...
-----END PRIVATE KEY-----"
```

`fastlane/.env`, `fastlane/metadata/`, `fastlane/screenshots/`는 `.gitignore`에 있다. 커밋하지 않는다.

## lane

`fastlane <lane>` 또는 `bundle exec fastlane <lane>`으로 실행한다.

| lane | 하는 일 | App Store Connect 변경 |
| --- | --- | --- |
| `release_status` | 출시된 버전, 출시 대기·심사 중·준비 중인 버전을 프로젝트 버전(`Projects/App/Project.swift`의 `MARKETING_VERSION`)과 비교한다. 마지막 줄에 `RELEASE_STATUS=READY`, `BUMP_REQUIRED`, `IN_REVIEW` 중 하나를 출력한다. | 없음 |
| `download_store_metadata` | 스토어 문구를 `fastlane/metadata/`로 받는다. `screenshots:true`를 붙이면 스크린샷도 `fastlane/screenshots/`로 받는다. | 없음 |
| `upload_store_metadata version:x.y.z` | 고친 문구를 올린다. `screenshots:true`를 붙이면 스크린샷도 덮어쓴다. 빌드 업로드와 심사 제출은 하지 않는다. | 문구 반영 |
| `beta` | Tuist로 프로젝트를 만들고, 빌드 번호를 정해 archive한 뒤 TestFlight에 올린다. | TestFlight 업로드 |
| `release version:x.y.z` | 버전을 바꿔 `beta`를 실행하고 심사 제출까지 한다. | 심사 제출 |

- `RELEASE_STATUS=BUMP_REQUIRED`는 프로젝트 버전과 같거나 높은 버전이 이미 승인됐다는 뜻이다. 이 버전으로는 TestFlight에 올릴 수 없으므로 `MARKETING_VERSION`을 올린다.
- `IN_REVIEW`는 같은 버전이 심사 중이라는 뜻이다. 새 빌드를 쓰려면 App Store Connect에서 심사를 취소하거나 버전을 올린다.

## 스토어 문구와 스크린샷

### 내려받기

App Store Connect는 바꾸지 않는다.

```bash
fastlane download_store_metadata
```

```bash
fastlane download_store_metadata screenshots:true
```

- 문구는 가장 최근 버전 기준으로 받는다. 스크린샷은 준비 중인 버전이 없으면 출시된 버전에서 받는다.
- 받는 파일(2026-10 기준):
  - `fastlane/metadata/{ko,en-US}/`: 이름, 부제, 설명, 키워드, 프로모션 문구, 출시 문구(`release_notes.txt`), URL
  - `fastlane/metadata/review_information/`: 심사 노트(`notes.txt`), 연락처, 테스트 계정
  - `fastlane/metadata/*category*.txt`, `copyright.txt`
  - `fastlane/screenshots/ko/`: 스크린샷 5장
- 테스트 계정 파일(`demo_user.txt`, `demo_password.txt`)은 출력하거나 공유하지 않는다.

### 갱신

1. `download_store_metadata`로 받은 파일을 고친다.
2. 문구를 올린다.

   ```bash
   fastlane upload_store_metadata version:1.1.8
   ```

3. 스크린샷까지 바꿨다면 `screenshots:true`를 붙인다. 언어 폴더(`fastlane/screenshots/ko/`)의 스크린샷으로 덮어쓴다.

   ```bash
   fastlane upload_store_metadata version:1.1.8 screenshots:true
   ```

- `version`의 버전이 App Store Connect에 없으면 새로 만든다.
- 내려받은 파일을 모두 다시 올리므로, 고치지 않은 파일도 지금 스토어 값과 같아야 한다. 오래전에 받은 파일이면 다시 받은 뒤 고친다.

### 출시 문구와 심사 노트 형식

- 출시 문구: 첫 줄 `■ {분류}`, 그 아래 `- ` 항목 1~4개. `ko`를 먼저 쓰고 `en-US`는 같은 뜻의 영어로 쓴다.
- 심사 노트: `[로그인 안내]`, `[업데이트 내용 안내]`, `[Login Instructions]`, `[Update Information]` 네 구역으로 쓴다. 출시마다 업데이트 구역의 항목만 바꾼다.

## 빌드 번호

`tuist generate`가 `CURRENT_PROJECT_VERSION`을 1로 되돌리므로, `beta`는 TestFlight에 있는 같은 버전의 마지막 빌드 번호에 1을 더해 쓴다. 새 버전의 첫 빌드는 1이다.

## Claude 출시 준비 스킬

Claude Code에서 `/poppang-app-store-release`를 입력하거나 "출시 준비해줘"라고 요청한다. 스킬은 `.claude/skills/poppang-app-store-release/`에 있고 Claude Code 전용이다.

| 단계 | 하는 일 | 사용자 확인 |
| --- | --- | --- |
| 1. 시작 점검 | 브랜치, 작업 트리, `gh` 로그인, 최신 `main`인지 확인한다. | |
| 2. 버전 확인 | `release_status`를 실행한다. 이미 승인된 버전이면 새 버전 번호를 묻는다. | 새 버전 번호 |
| 3. 버전 올리기 | 버전을 올려야 할 때만 이슈 `[chore] {버전} 출시를 준비한다`, 브랜치, 버전 커밋, PR을 만든다. | |
| 4. 출시 범위 | 마지막 출시 태그 이후 머지된 PR에서 사용자에게 보이는 변경만 고른다. | 출시 범위 |
| 5. 문구 받기 | `download_store_metadata`를 실행한다. | |
| 6~7. 문구 쓰기 | 출시 문구(ko·en-US)와 심사 노트 업데이트 구역(한글·영문)을 쓴다. | |
| 8. 검사 | `scripts/validate_metadata.py`로 형식을 검사한다. | 최종 문구 |
| 9. 문구 반영 | `upload_store_metadata`를 실행한다. | |
| 10. 업로드 | `beta`로 TestFlight에 올린다. | |
| 11. 보고 | 버전, 빌드 번호, 반영한 문구, PR 링크, 남은 일을 정리한다. | |

심사 제출은 하지 않는다.

## 출시한 뒤

1. App Store Connect에서 빌드를 고르고 심사를 제출한다.
2. 출시한 뒤 GitHub Actions의 `Release with Notes` workflow(`.github/workflows/5. release.yml`)를 버전 번호로 실행한다. `v{버전}` 태그와 GitHub 릴리스가 만들어지고, 다음 출시 범위의 기준이 된다.

## 관련 문서

- [Git 작업 흐름](gitflow.md)
- [Tuist 설치와 실행](tuist.md)
- [AI 작업 흐름](ai-workflow.md)
