# PopPang Git 작업 흐름

이 문서는 PopPang 저장소에서 이슈, 브랜치, 커밋, PR을 만드는 규칙을 정리한다. 에이전트가 커밋하거나 PR을 만들 때는 `.agents/skills/auto-commit-push`, `.agents/skills/auto-pr` 스킬과 이 문서를 함께 따른다.

## 저장소 기본값

| 항목 | 값 | 근거 |
| --- | --- | --- |
| 기본 브랜치 | `main` | `origin/HEAD` |
| 원격 | `origin` (GitHub) | `git remote -v` |
| 이슈 템플릿 | `.github/ISSUE_TEMPLATE/issue.md` | |
| PR 템플릿 | `.github/PULL_REQUEST_TEMPLATE.md` | |
| 이슈 브랜치 자동 생성 | `.github/issue-branch.yml`, `.github/workflows/4. issue-auto-branch.yml` | |
| 라벨 | `.github/labels.json` | |
| 병합 방식 | squash merge. `main`의 커밋 제목은 `PR 제목 (#PR번호)`가 된다. | 최근 `main` 이력 |

## 전체 흐름

```text
이슈 생성(라벨 지정) → 이슈 assign → 이슈 브랜치 자동 생성 → fetch·checkout
→ 작업·검증 → 커밋(type: 한글 설명) → push → PR 생성 → 리뷰 → squash merge
```

## 1. 이슈

- 제목은 `[type] 한글 설명`으로 쓰고 `-다`로 끝낸다. 예: `[feat] 네이버 지도 연구용 MapFeatureDemo를 구성한다`, `[fix] 프로필 닉네임 변경 후 홈 헤더가 갱신되지 않는 문제를 해결한다`
- 본문은 템플릿의 `💡 Issue`, `📁 작업할 파일`, `🔥 Tasks`, `🎨 스크린샷(선택)`을 채운다.
- 라벨은 아래 중 하나를 붙인다. 라벨이 브랜치 접두사를 정한다.
- 에이전트는 사용자가 요청할 때만 이슈를 만든다.

## 2. 브랜치

이슈 브랜치는 `.github/workflows/4. issue-auto-branch.yml`이 `.github/issue-branch.yml` 규칙으로 만든다. 이 workflow는 이슈가 assign되거나 이슈 댓글이 달릴 때 실행된다. 브랜치 이름은 `<접두사>/#<이슈번호>`다.

| 이슈 라벨 | 브랜치 접두사 | 예 |
| --- | --- | --- |
| `✨ feature` | `feature/` | `feature/#93` |
| `🔧 fix` | `fix/` | `fix/#91` |
| `🔥 hotfix` | `hotfix/` | `hotfix/#<이슈번호>` |
| `⚙️ chore` | `chore/` | `chore/#<이슈번호>` |
| `🔨 refactor` | `refactor/` | `refactor/#65` |
| `✅ test` | `test/` | `test/#89` |
| `📃 docs` | `docs/` | `docs/#81` |

자동 생성된 브랜치를 받아서 작업한다.

```bash
git fetch origin
git switch feature/#93
```

이슈 없이 작업을 시작해야 하면 `<접두사>/<짧은-설명>`으로 만들고, 이슈가 생기면 PR 전에 브랜치 이름을 맞춘다. 한 브랜치에는 한 가지 목적만 담는다.

## 3. 커밋

작업 중 커밋 메시지는 `type: 한글 설명` 형식이다.

| type | 사용 시점 | 예 |
| --- | --- | --- |
| `feat` | 새 기능, 새 화면, 사용자에게 보이는 기능 | `feat: 지도 데모 내 위치 이동 추가` |
| `fix` | 버그 수정, 깨진 동작 복구 | `fix: 지도 이동 시 가까운순 목록 갱신` |
| `refactor` | 동작을 유지한 구조 개선 | `refactor: 데모 이미지 프리패칭을 URLSession으로 전환한다` |
| `docs` | 문서, `AGENTS.md`, README만 바뀐 경우 | `docs: 지도 데모 카메라 흐름 문서화` |
| `chore` | 설정, 정리, 버전 변경 같은 운영 작업 | `chore: 1.1.4 -> 1.1.5 버전 변경` |
| `ci` | 배포·자동화·파이프라인 변경이 핵심인 경우 | `ci: makefile 수정` |

- 한 커밋에는 하나의 논리적 변경만 담는다. 서로 관계없는 변경이 섞였으면 나눈다.
- 커밋할 파일만 경로를 지정해 stage한다. `git add .`과 `git commit -a`를 쓰지 않는다.
- stage한 내용을 `git diff --cached --stat`과 `git diff --cached`로 확인한 뒤 커밋한다.
- AI 공동 작성자 트레일러와 생성 문구를 넣지 않는다. ([AI 작성 표기 규칙](ai-attribution.md))
- 커밋은 사용자가 요청할 때만 한다.

## 4. push

- 사용자가 push를 명시적으로 요청할 때만 한다. 단, PR 생성 요청에는 현재 브랜치 push가 포함된다.
- push 전에 `git branch --show-current`로 브랜치를 확인한다.
- 원격 브랜치가 없으면 `git push -u origin <branch>`를 쓴다.
- `main`이나 공유 브랜치에 `--force` push를 하지 않는다.

### push 전 Claude 코드 리뷰 hook

브랜치를 push하기 직전에 Claude Code의 `code-review` 스킬로 변경을 리뷰하는 `pre-push` hook을 쓸 수 있다. 개인 설정이라 `.githooks/`는 `.gitignore`에 들어 있고 커밋하지 않는다.

설정 방법:

```bash
npx --yes --package=github:indextrown/codex-skillbook -- project-docs hooks ios-uikit
```

이 명령은 설정할지 물은 뒤 `.githooks/pre-push`를 만들고 `git config core.hooksPath .githooks`를 설정한다. 확인 질문 없이 바로 적용하려면 `--apply`를 붙이고(에이전트가 실행할 때), 바뀔 내용만 보려면 `--dry-run`을 붙인다. 설정 여부는 아래로 확인한다.

```bash
git config core.hooksPath    # .githooks 이면 설정됨
```

| 항목 | 동작 |
| --- | --- |
| 리뷰 범위 | 첫 push와 강제 push는 `main`에서 갈라진 뒤의 전체 변경, 이후 push는 새로 올라가는 커밋만 리뷰한다. |
| 판정 | 정확성 버그·크래시·데이터 손실·보안 문제가 있으면 `FAIL`이고 push를 막는다. 정리·스타일 제안은 막지 않는다. |
| 건너뛰는 경우 | 브랜치 삭제, 태그 push, `main` 직접 push, 변경이 없는 push |
| 설정값 | `CLAUDE_REVIEW_LEVEL`(기본 `medium`), `CLAUDE_REVIEW_TIMEOUT`(기본 900초) |
| 필요한 도구 | 로그인한 `claude` CLI, `jq`, `perl`. 없으면 리뷰가 필요한 push를 막는다. |
| 결과 원본 | 리뷰 `.git/claude-review-last.json`, 판정 `.git/claude-review-verdict.json` |
| 우회 | `git push --no-verify`. 사용자가 요청할 때만 쓴다. |

- push 한 번에 수십 초에서 몇 분이 걸리고 API 비용이 든다.
- `core.hooksPath`를 바꾸면 `.git/hooks`의 hook은 더 이상 실행되지 않는다. 다른 hook(Git LFS 등)을 쓰고 있다면 설정하지 않는다.
- 설정을 원하지 않으면 `git config project-docs.gitHooks declined`로 기록한다.
- `FAIL`이 나면 지적된 문제를 고치고 다시 push한다.

## 5. PR

- 본문은 `.github/PULL_REQUEST_TEMPLATE.md`의 섹션 순서를 유지한다: `💡 PR 유형`, `✏️ 변경 사항`, `🚨 관련 이슈`(`- close #이슈번호`), `🎨 스크린샷`, `✅ 체크리스트`, `🔥 추가 설명`.
- 변경 사항은 `- ...했습니다.` 문체의 bullet로 쓴다. 문체와 예시는 `.agents/skills/auto-pr/references/pr-writing-style.md`를 따른다.
- 체크리스트는 실제로 확인한 항목만 체크한다. 검증하지 못했으면 추가 설명에 이유를 적는다.
- 게시는 `gh pr create --base main --head <branch> --title "<제목>" --body-file <파일> --assignee @me --label "<라벨>"`로 한다.
- 같은 브랜치의 열린 PR이 있으면 새로 만들지 않는다.

### PR 제목

PR 제목은 연결된 이슈 제목과 똑같이 쓴다. 형식은 `[type] 한글 설명`이고 `-다`로 끝낸다.

| 이슈 제목 | PR 제목 |
| --- | --- |
| `[feat] 네이버 지도 연구용 MapFeatureDemo를 구성한다` | `[feat] 네이버 지도 연구용 MapFeatureDemo를 구성한다` |
| `[fix] 프로필 닉네임 변경 후 홈 헤더가 갱신되지 않는 문제를 해결한다` | `[fix] 프로필 닉네임 변경 후 홈 헤더가 갱신되지 않는 문제를 해결한다` |

- 이슈 제목을 요약하거나 문체를 바꾸지 않는다.
- `[#이슈번호] 설명` 형식(예: `[#93] ...`)은 쓰지 않는다. 이슈 번호는 본문의 `- close #93`과 브랜치 이름으로 연결한다.
- 사용자가 제목을 지정하면 그 제목을 쓴다. 연결할 이슈가 없다고 사용자가 말한 경우에는 변경 내용으로 `[type] 한글 설명`을 직접 쓴다.
- squash merge하면 `main` 커밋 제목 끝에 `(#PR번호)`가 붙는다.
- PR 제목을 자동으로 바꾸는 workflow는 없다. `auto-pr` 스킬이 이슈 제목을 그대로 가져와 제목을 만든다.

### PR 댓글 명령

PR에 아래 댓글을 달면 `6. pr-command.yml`이 해당 workflow를 실행한다.

| 댓글 | 실행하는 workflow |
| --- | --- |
| `/팝팡 빌드` | `1. poppang-build.yml` |
| `/팝팡 테스트` | `2. poppang-test.yml` |
| `/팝팡 빌드하고테스트` | `3. poppang-build-and-test.yml` |
| `/팝팡 버전점검`, `/팝팡 의존성점검` | `0. poppang-dependency-canary.yml` |

### 병합 후

- 이슈 브랜치 workflow가 병합된 PR의 head 브랜치를 자동으로 지운다.
- `autoCloseIssue: true`라서 연결된 이슈가 닫힌다.
- 로컬에서는 `git switch main && git pull --ff-only origin main`으로 최신화하고, 다른 사람이 쓰지 않는 로컬 브랜치를 지운다.

## 커밋·PR 전 체크리스트

- [ ] 현재 브랜치가 작업 이슈와 맞다. `main`에서 직접 작업하지 않는다.
- [ ] stage한 파일이 모두 이번 작업과 관련 있다.
- [ ] `.env`, `*.xcconfig`, `GoogleService-Info.plist`, `.codex/logs/*.jsonl`, Tuist·Xcode 생성물, 빌드 산출물이 없다.
- [ ] 커밋 메시지와 PR 제목이 위 형식을 따른다.
- [ ] AI 공동 작성자 트레일러, 생성 문구, 세션 링크가 없다.
- [ ] 빌드·테스트를 실행했거나 실행하지 못한 이유를 남겼다.

## 안전 규칙

- `git reset --hard`, `git checkout -- <파일>`, `git restore <파일>`은 커밋하지 않은 변경을 지울 수 있다. 대상을 확인하지 않고 실행하지 않는다.
- 이미 push한 커밋의 이력을 다시 쓰지 않는다. 필요하면 사용자에게 먼저 확인한다.
- 비밀키, 토큰, 개인 `xcconfig`를 커밋하지 않는다.

## 관련 문서

- [AI 작성 표기 규칙](ai-attribution.md)
- [AI 작업 흐름](ai-workflow.md)
- [테스트](testing.md)
