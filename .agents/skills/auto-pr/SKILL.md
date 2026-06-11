---
name: auto-pr
description: PopPang iOS 앱 프로젝트 전용 GitHub Pull Request 자동 작성 및 게시 워크플로우. 사용자가 "PR 올려줘", "pr 생성해", "자동 PR", "풀리퀘 만들어줘", "github pr 올려줘"처럼 현재 브랜치의 커밋을 바탕으로 PR 제목/본문을 만들고 게시하라고 요청할 때 사용한다. 기존 `.github/PULL_REQUEST_TEMPLATE.md`, git log/diff, 커밋 내용, PopPang 기존 PR 문체를 반영해 `gh pr create`로 PR을 생성한다.
---

# Auto PR

## 목적

PopPang 저장소에서 현재 브랜치의 커밋과 변경사항을 분석해 기존 PR 템플릿과 문체에 맞는 PR 제목/본문을 작성하고 GitHub에 게시한다.

실제 PR 게시는 사용자가 PR 생성/게시를 명시한 경우에만 수행한다. 사용자가 "본문만 작성해", "초안만 만들어줘"처럼 요청하면 `gh pr create`를 실행하지 않는다.

## 참고 파일

PR 작성 전에 아래 파일을 읽는다.

1. `.github/PULL_REQUEST_TEMPLATE.md`
2. `references/pr-writing-style.md`

두 파일 중 하나를 읽을 수 없으면 PR을 만들기 전에 사용자에게 누락 경로를 알리고, 현재 확인 가능한 정보로 진행 가능한지 판단한다.

## 사전 점검

아래 순서로 확인한다.

1. `git status --short`로 working tree 상태를 확인한다.
2. uncommitted 변경이 있으면 PR 생성 전에 중단한다. 사용자가 명시적으로 원하면 먼저 `$auto-commit-push`로 커밋하게 안내한다.
3. `.env`, `*.xcconfig`, `GoogleService-Info.plist`, `.codex/logs/*.jsonl`, Xcode/Tuist 생성물, 인증키/토큰/비밀번호가 변경사항에 보이면 PR 생성을 중단하고 사용자에게 보고한다.
4. `git branch --show-current`로 현재 브랜치를 확인한다.
5. 현재 브랜치가 `main`이면 PR 생성을 중단한다.
6. `git remote -v`와 `gh auth status`로 GitHub remote와 인증 상태를 확인한다.
7. `gh repo view --json defaultBranchRef,nameWithOwner,url`로 기본 브랜치와 저장소를 확인한다.
8. `git fetch origin <base>`로 base 브랜치 정보를 갱신한다.
9. `git log --oneline origin/<base>..HEAD`로 PR에 들어갈 커밋이 있는지 확인한다.
10. `gh pr list --head <current-branch> --state open --json number,title,url`로 중복 PR이 있는지 확인한다.

중복 PR이 있으면 새 PR을 만들지 말고 기존 PR URL을 보고한다. 사용자가 "기존 PR 업데이트"를 명시한 경우에만 `gh pr edit`을 검토한다.

## 분석 명령

PR 제목과 본문을 만들 때 아래 정보를 사용한다.

```bash
git log --oneline origin/<base>..HEAD
git diff --stat origin/<base>...HEAD
git diff --name-status origin/<base>...HEAD
git diff --shortstat origin/<base>...HEAD
```

필요하면 변경 파일을 선별해 `git diff origin/<base>...HEAD -- <path>`로 확인한다.

`.codex/logs/*.jsonl`은 비밀이나 개인정보가 포함될 수 있으므로 기본 입력으로 사용하지 않는다. 사용자가 명시적으로 "Codex 로그도 참고해"라고 요청한 경우에만 필요한 범위에서 요약 정보만 읽고 PR 본문에 원문을 붙이지 않는다.

## 이슈 번호 추론

관련 이슈 번호는 아래 순서로 찾는다.

1. 브랜치명에서 `#<number>`를 찾는다. 예: `feature/#15`, `fix/#18`, `refactor/#23`
2. 커밋 메시지에서 `#<number>`를 찾는다.
3. 사용자 요청에 포함된 이슈 번호를 사용한다.

이슈 번호를 찾을 수 없으면 PR 생성을 중단하고 사용자에게 이슈 번호를 물어본다. 사용자가 관련 이슈가 없다고 명시한 경우에는 `관련 이슈 없음`으로 작성하고 체크리스트의 관련 이슈 항목은 체크하지 않는다.

이슈 번호를 찾으면 반드시 이슈 제목을 조회한다.

```bash
gh issue view <issue-number> --json number,title,url,state
```

사용자가 PR 제목을 명시하지 않았다면 PR 제목은 조회한 이슈 제목과 정확히 같게 쓴다. 이슈 제목을 임의로 요약하거나 문체를 바꾸지 않는다.

## 타입 결정

PR 유형 체크박스와 라벨은 이슈 제목, branch prefix, commit prefix, 변경 파일을 함께 보고 결정한다.

type 매핑:

- `feat`: 기능 추가
- `fix`: 일반 버그 수정
- `hotfix`: 긴급 버그 수정
- `chore`: 환경 설정 및 기타 작업
- `refactor`: 코드 개선
- `test`: 테스트 코드 작성
- `docs`: 문서 작성 및 수정

라벨 매핑:

- `feat` -> `✨ feature`
- `fix` -> `🔧 fix`
- `hotfix` -> `🔥 hotfix`
- `chore` -> `⚙️ chore`
- `refactor` -> `🔨 refactor`
- `test` -> `✅ test`
- `docs` -> `📃 docs`

기존 PR처럼 여러 PR 유형이 섞이면 본문 체크박스는 복수로 체크한다. 제목 type은 사용자가 제목을 따로 요구했거나 이슈 제목을 가져올 수 없는 예외 상황에서만 가장 핵심적인 변경 하나를 고른다.

## 제목 작성

제목 우선순위:

1. 사용자가 PR 제목을 명시하면 그 제목을 사용한다.
2. 관련 이슈 번호를 찾고 `gh issue view`로 이슈 제목을 가져올 수 있으면 이슈 제목을 그대로 사용한다.
3. 이슈가 없다고 사용자가 명시한 경우에만 변경 내용으로 제목을 직접 작성한다.

직접 제목을 작성해야 하는 예외 상황에서만 아래 형식을 사용한다.

```text
[type] 한글 작업 요약
```

문체:

- 기능/구조 도입: `...를 도입한다`
- 분리/구조 개선: `...를 분리한다`, `...로 재구성한다`
- 버그 수정: `...문제를 해결한다`
- 문서/운영 정리: `...를 정리한다`

예:

```text
[feat] 관리자 팝업 요청 리스트를 도입한다
[fix] BottomSheet의 런타임 duplicate class 경고와 크래시 문제를 해결한다
[refactor] AdMob 네이티브 광고를 모듈로 분리한다
[docs] Codex 작업 규칙과 PR 자동화 문서를 정리한다
```

## 본문 작성

템플릿의 섹션과 순서를 유지한다.

```text
## 💡 PR 유형
## ✏️ 변경 사항
## 🚨 관련 이슈
## 🎨 스크린샷
## ✅ 체크리스트
## 🔥 추가 설명
```

작성 규칙:

- 템플릿의 HTML 주석은 제거해도 된다.
- 변경 사항은 보통 4-8개의 한글 bullet로 작성한다.
- bullet은 `- ...했습니다.` 문체를 기본으로 쓴다.
- 기술적 배경이 중요한 PR은 `### 문제 원인`, `### 해결 내용`, `### 문서화`, `### 검증한 내용`, `### 추가 확인 필요` 같은 하위 섹션을 추가한다.
- CodeRabbit 자동 요약 블록은 직접 작성하지 않는다.
- UI 변경이 없으면 기본 스크린샷 테이블을 유지하고 빈 `GIF` placeholder를 둔다.
- UI 변경이 있고 사용자가 이미지/GIF URL을 제공하지 않았으면 screenshot placeholder를 유지하고 추가 설명에 "스크린샷은 별도 첨부 필요"를 적는다.

체크리스트는 사실대로 표시한다.

- 코드/커밋 컨벤션: 커밋 메시지와 PR 제목이 규칙에 맞으면 체크한다.
- Assignees/Reviewers: `--assignee @me`를 설정했거나 사용자 지정 assignee/reviewer를 설정하면 체크한다. reviewer가 없는 저장소면 assignee 설정만으로 체크 가능하다.
- 정상 동작 확인: 빌드/테스트/수동 검증 중 하나라도 확인했으면 체크한다. 검증하지 못했으면 체크하지 않고 추가 설명에 미검증 이유를 적는다.
- 관련 이슈: 이슈 번호를 작성했으면 체크한다.

## 게시 절차

PR 본문은 shell inline 문자열보다 임시 body file로 전달한다.

1. 제목과 본문을 사용자에게 짧게 요약하되, 사용자가 이미 PR 생성을 요청했다면 별도 승인 대기 없이 계속 진행한다.
2. 브랜치가 원격에 없거나 원격보다 앞서 있으면 `git push -u origin <current-branch>` 또는 `git push`를 실행한다. PR 생성 요청은 현재 브랜치 게시를 포함한다고 본다.
3. 아래 형식으로 PR을 생성한다.

```bash
gh pr create \
  --base <base> \
  --head <current-branch> \
  --title "<title>" \
  --body-file <body-file> \
  --assignee @me \
  --label "<primary-label>"
```

4. 사용자가 draft를 요청했거나 검증이 불충분해 draft가 더 적절하면 `--draft`를 붙인다.
5. PR 생성 후 URL을 보고한다.

라벨이 없거나 권한 문제로 실패하면 PR 생성 자체를 재시도하지 말고, PR URL과 라벨 추가 실패 이유를 함께 보고한다.

## 실패와 중단 기준

아래 상황에서는 PR을 생성하지 않는다.

- working tree에 커밋되지 않은 변경이 있다.
- 금지 파일이나 비밀이 변경사항에 포함되어 있다.
- 현재 브랜치가 `main`이다.
- base 대비 커밋이 없다.
- 관련 이슈 번호가 없고 사용자가 "이슈 없음"을 명시하지 않았다.
- `gh auth status`가 실패한다.
- 같은 head branch의 open PR이 이미 있다.
- PR 제목/본문을 만들기에 diff 정보가 부족하다.

중단 시에는 무엇이 막혔는지와 다음 명령 또는 다음 사용자 입력을 짧게 제시한다.

## 최종 응답

PR을 생성했다면 아래를 보고한다.

- PR URL
- 제목
- base/head branch
- 관련 이슈
- push 여부
- 검증/미검증 요약

PR을 생성하지 않았다면 중단 이유와 필요한 다음 조치를 보고한다.
