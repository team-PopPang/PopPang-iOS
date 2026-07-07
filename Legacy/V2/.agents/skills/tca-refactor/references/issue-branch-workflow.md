# Issue Branch Workflow

이 문서는 PopPang 저장소의 issue -> assign -> auto branch 생성 -> local checkout 흐름을 정리한다.

현재 기준은 아래 설정 파일을 따른다.

- `.github/workflows/4. issue-auto-branch.yml`
- `.github/issue-branch.yml`
- `.github/labels.json`

## 기본 원칙

1. 기존 issue가 있으면 그 issue부터 시작한다.
2. issue가 없으면 `global-auto-issue`를 사용해 먼저 만든다.
3. issue assign은 원격 write 작업이므로 매번 사용자 승인 후에만 진행한다.
4. 승인 문구는 아래 문장을 그대로 사용한다.

```text
새로운 브랜치를 열기 위해 해당 이슈에 assign을 할당해도 되겠습니까?
```

5. 사용자가 수락하기 전에는 assign, branch 생성 트리거, 원격 fetch/checkout을 실행하지 않는다.

## Assign 후 브랜치 생성 규칙

GitHub workflow는 issue에 assignee가 지정되면 자동 실행된다.

브랜치 이름 규칙:

```text
<prefix>#<issue-number>
```

prefix는 issue label에 따라 결정된다.

- `✨ feature` -> `feature/`
- `🔧 fix` -> `fix/`
- `🔥 hotfix` -> `hotfix/`
- `⚙️ chore` -> `chore/`
- `🔨 refactor` -> `refactor/`
- `✅ test` -> `test/`
- `📃 docs` -> `docs/`

예:

- `#29` + `🔨 refactor` -> `refactor/#29`
- `#25` + `✨ feature` -> `feature/#25`

## Assign 절차

1. issue 번호를 확인한다.
2. 현재 인증된 GitHub 사용자를 확인한다.
3. 사용자 승인 문구를 보낸다.
4. 사용자가 수락하면 현재 인증된 사용자에게 issue를 assign한다.
5. 몇 초 기다린 뒤 issue comment 또는 원격 브랜치 생성을 확인한다.

assign 대상은 기본적으로 현재 `gh auth status`에 표시되는 사용자다. 사용자가 다른 계정을 명시하면 그 계정을 따른다.

## 브랜치 생성 확인 절차

우선순위:

1. issue comment에서 branch 생성 메시지 확인
2. `git branch -r`에서 `origin/<prefix>#<issue-number>` 확인

자동화 comment 예시:

```text
Branch refactor/#29 created for issue: ...
```

comment가 아직 없으면 바로 포기하지 말고 몇 초 뒤 다시 확인한다.

## 로컬 checkout 절차

브랜치명에 `#`가 들어가므로 quoting을 유지한다.

예:

```bash
git fetch origin 'refactor/#29'
git switch -c 'refactor/#29' --track 'origin/refactor/#29'
```

이미 로컬 브랜치가 있으면:

```bash
git switch 'refactor/#29'
git pull --ff-only origin 'refactor/#29'
```

실제 prefix는 issue label을 기준으로 계산하되, 가능하면 원격 브랜치 존재를 먼저 확인한다.

## 구현 중 규칙

1. issue 범위를 벗어나는 `Domain`, `Data`, `Coordinator`, `App` public contract 변경이 필요해지면 작업을 멈추고 다시 승인받는다.
2. 기본 구현 대상은 루트 `Projects/*`다.
3. `V1/*`는 비교용으로만 읽는다.

## 마무리 흐름

1. 구현 완료 후 검증 결과를 정리한다.
2. 사용자가 커밋/푸시를 원하면 `auto-commit-push`를 사용한다.
3. 사용자가 PR 생성까지 원하면 `auto-pr`를 사용한다.
4. 사용자가 `auto-commit-pr`라고 표현해도 실제 프로젝트 스킬은 `auto-pr`로 해석한다.
5. PR 생성 후 최종 merge 판단은 사용자에게 남긴다.

## 이 문서를 업데이트할 때

아래가 바뀌면 이 문서를 수정한다.

- issue label -> branch prefix mapping
- assign trigger 방식
- branch comment 문구
- fetch/checkout 방식
- 마무리 workflow에서 쓰는 스킬 이름
