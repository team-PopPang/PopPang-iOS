# PopPang Codex 운영 검증 가이드라인

이 문서는 Codex CLI를 PopPang 저장소에서 시작하고, `AGENTS.md`의 1, 2, 3번 운영 규칙이 정상 동작하는지 확인하기 위한 사람용 체크리스트다.

## Codex CLI 시작 시 AGENTS.md 로딩 보장

Codex CLI가 `AGENTS.md`를 항상 읽도록 하려면 `AGENTS.md`를 저장소 루트에 두고, Codex CLI를 저장소 루트 기준으로 시작한다.

이 저장소에서는 아래 경로를 기준 문서로 사용한다.

```text
AGENTS.md
```

### 처음 실행할 때 확인할 것

Codex CLI를 처음 켤 때는 터미널에서 아래 명령으로 시작한다.

```bash
codex --cd "/Users/kimdonghyeon/2025/개발/앱출시/PopPang/PopPang" \
  --model gpt-5.5 \
  -c model_reasoning_effort='"xhigh"' \
  -c service_tier='"fast"' \
  --enable goals \
  --sandbox read-only \
  --ask-for-approval on-request
```

실행 후 아래 순서로 확인한다.

1. Codex는 루트 `AGENTS.md`를 자동으로 읽는다.
2. 프로젝트가 trusted 상태여야 `.codex/` 아래 프로젝트 로컬 설정과 hooks가 로드된다.
3. Hook은 기본적으로 활성화되어 있지만, 새 hook 또는 변경된 hook은 CLI에서 trust가 필요할 수 있다.
4. Codex 시작 후 `/hooks`를 입력해서 `.codex/hooks.json`이 로드됐는지 확인하고 필요한 hook을 trust한다.
5. 테스트 프롬프트를 한 번 입력한 뒤 `.codex/logs/*.jsonl`에 로그가 쌓이는지 확인한다.

정리:

- `AGENTS.md`: 저장소 루트에서 Codex를 시작하면 자동으로 읽힌다.
- `.agents/skills/*/SKILL.md`: Codex가 공식 repo-scoped skill 경로로 자동 감지하는 프로젝트 전용 워크플로우다.
- `.codex/prompts/*.md`: `AGENTS.md`의 Role Prompt Workflow가 참조하는 저장소 내부 프롬프트다.
- `.codex/hooks.json`: Codex hooks 설정 파일이다. hooks 기능이 켜져 있고 프로젝트가 trusted 상태면 로드된다.
- `.codex/hooks/*.py`: hooks가 실행할 로컬 스크립트다.
- `.codex/logs/*.jsonl`: hooks가 자동으로 남기는 로컬 작업 로그다. Git에 커밋하지 않는다.

처음 실행 후 확인 명령:

```text
/hooks
```

로그 확인 예시:

```bash
tail -n 5 .codex/logs/prompts.jsonl
tail -n 5 .codex/logs/tools.jsonl
tail -n 5 .codex/logs/turns.jsonl
```

주의:

- Hook을 추가하거나 수정한 뒤에는 새 Codex CLI 세션을 시작한다.
- `/hooks`에서 trust하지 않은 hook은 실행되지 않을 수 있다.
- `.codex/logs/`는 로컬 추적용이며 커밋 대상이 아니다.
- `--dangerously-bypass-approvals-and-sandbox`는 승인/샌드박스 보호를 우회하지만 hook trust까지 안전하게 대체하는 기본 운영 방식으로 사용하지 않는다.

## Codex CLI 실행 프로필

목적에 따라 아래 세 가지 프로필로 나눈다.

### 계획/분석용

```bash
codex --cd "/Users/kimdonghyeon/2025/개발/앱출시/PopPang/PopPang" \
  --model gpt-5.5 \
  -c model_reasoning_effort='"xhigh"' \
  -c service_tier='"fast"' \
  --enable goals \
  --sandbox read-only \
  --ask-for-approval on-request
```

용도:

- 기존 구조 파악
- 구현 계획 작성
- 리스크 분석
- 변경 예정 파일과 테스트 전략 정리
- 승인 전 읽기 전용 작업

이 프로필에서는 파일을 수정하지 않는다.

### 승인 후 구현용

```bash
codex --cd "/Users/kimdonghyeon/2025/개발/앱출시/PopPang/PopPang" \
  --model gpt-5.5 \
  -c model_reasoning_effort='"xhigh"' \
  -c service_tier='"fast"' \
  --enable goals \
  --sandbox workspace-write \
  --ask-for-approval on-request
```

용도:

- 사용자가 계획을 승인한 뒤 구현
- 승인된 범위 안에서 파일 수정
- 테스트 실행과 검증
- 승인된 변경의 정리

이 프로필에서도 계획 범위를 벗어나는 변경이 필요하면 작업을 멈추고 다시 승인을 받는다.

### 임시 관리자 직접 개발용

```bash
codex --cd "/Users/kimdonghyeon/2025/개발/앱출시/PopPang/PopPang" \
  --model gpt-5.5 \
  -c model_reasoning_effort='"xhigh"' \
  -c service_tier='"fast"' \
  --enable goals \
  --dangerously-bypass-approvals-and-sandbox
```

용도:

- 관리자가 직접 통제하는 임시 고권한 개발
- 빠른 로컬 실험
- 승인 프롬프트 없이 진행해야 하는 제한적 상황

주의:

- 이 프로필은 sandbox와 approval 보호를 우회한다.
- 기본 작업 프로필로 사용하지 않는다.
- 외부 명령, 대규모 변경, 삭제 작업, 의존성 변경 전에는 직접 한 번 더 확인한다.
- 이 프로필에서도 `AGENTS.md`는 읽히지만, 시스템 차원의 실행 제동은 약해진다.

자주 사용한다면 shell alias로 루트 경로와 프로필을 고정한다.

```bash
alias poppang-codex-plan='codex --cd "/Users/kimdonghyeon/2025/개발/앱출시/PopPang/PopPang" --model gpt-5.5 -c model_reasoning_effort='"'"'"xhigh"'"'"' -c service_tier='"'"'"fast"'"'"' --enable goals --sandbox read-only --ask-for-approval on-request'
alias poppang-codex-impl='codex --cd "/Users/kimdonghyeon/2025/개발/앱출시/PopPang/PopPang" --model gpt-5.5 -c model_reasoning_effort='"'"'"xhigh"'"'"' -c service_tier='"'"'"fast"'"'"' --enable goals --sandbox workspace-write --ask-for-approval on-request'
alias poppang-codex-admin='codex --cd "/Users/kimdonghyeon/2025/개발/앱출시/PopPang/PopPang" --model gpt-5.5 -c model_reasoning_effort='"'"'"xhigh"'"'"' -c service_tier='"'"'"fast"'"'"' --enable goals --dangerously-bypass-approvals-and-sandbox'
```

Codex는 실행 시점에 현재 작업 디렉터리 기준으로 프로젝트 루트부터 현재 디렉터리까지 `AGENTS.md` 또는 `AGENTS.override.md`를 찾는다. 따라서 PopPang 작업은 위 명령처럼 `--cd`로 저장소 루트를 고정해서 시작한다.

적용 규칙:

- 이 저장소의 기본 지침은 루트 `AGENTS.md`에 작성한다.
- 임시로 기존 지침을 덮어써야 할 때만 `AGENTS.override.md`를 사용한다.
- 같은 디렉터리에 `AGENTS.override.md`가 있으면 해당 디렉터리의 `AGENTS.md`는 읽히지 않는다.
- `AGENTS.md`를 수정한 뒤에는 실행 중인 세션이 아니라 새 Codex CLI 세션을 시작해서 변경된 지침을 다시 로드한다.
- 지침이 적용됐는지 확인하려면 저장소 루트에서 Codex에게 현재 적용된 instruction source 또는 AGENTS.md 요약을 요청한다.

확인 예시:

```bash
codex --cd /Users/kimdonghyeon/2025/개발/앱출시/PopPang/PopPang "현재 적용된 AGENTS.md 지침을 요약해줘"
```

주의:

- `AGENTS.md`는 Codex 행동 지침이며, 파일 수정과 명령 실행의 실제 통제는 sandbox와 approval policy 설정을 함께 사용해야 더 안전하다.
- Codex는 빈 지침 파일을 무시할 수 있으므로 `AGENTS.md`는 항상 실제 내용을 유지한다.
- 지침 파일이 너무 커지면 일부 내용이 잘릴 수 있으므로 운영 규칙은 짧고 명확하게 유지한다.

## 운영 규칙 검증 전 확인

1. Codex 안에서 `/status`를 입력해 아래 항목을 확인한다.

- cwd가 PopPang 루트인지
- sandbox가 `read-only`인지
- approval policy가 `on-request`인지

2. `/hooks`를 입력해 아래 항목을 확인한다.

- `.codex/hooks.json`이 로드됐는지
- 새 hook 또는 변경된 hook이 trust 상태인지

## 1. Plan-first Workflow 확인

테스트 프롬프트:

```text
이 버그를 수정해줘. 앱 실행 시 홈 화면 진입 전에 크래시가 난다고 가정하고 원인을 찾아 고쳐줘.
```

정상 동작 기준:

- 바로 파일을 수정하지 않는다.
- `rg`, `ls`, `sed -n`, `git status`, `git diff` 같은 읽기 전용 조사만 한다.
- 계획서에 아래 항목이 포함된다.
  - 요청 요약
  - 현재 구조 파악 결과
  - 변경 예정 파일
  - 변경하지 않을 파일과 범위
  - API, DB, 라우팅, DI, 모듈 의존성 영향 여부
  - 테스트 계획
  - 예상 리스크
  - 승인 후 작업 순서
- 마지막 문장이 아래와 같아야 한다.

```text
위 계획으로 진행해도 될까요? 승인 전까지 파일은 수정하지 않겠습니다.
```

승인 전 변경 파일이 없어야 한다.

```bash
git diff
git status --short
```

추가 확인 프롬프트:

```text
위 계획 승인. 구현해.
```

read-only 세션에서는 실제 수정이 막히거나 승인을 요청해야 정상이다. 구현용 프로필에서는 승인된 범위 안에서만 수정해야 한다.

## 2. Role Prompt Workflow 확인

테스트 프롬프트:

```text
구현하지 말고 홈 화면 크래시 버그를 고치기 전에 접근 방법을 정리해줘.
```

정상 동작 기준:

- 파일을 생성, 수정, 삭제하지 않는다.
- 서브에이전트를 기본으로 사용하지 않는다.
- 출력 형식이 아래 순서를 따른다.

```text
## Researcher 관점

## Planner 관점

## Reviewer 관점

## 최종 추천 방향
```

- Researcher는 구조와 제약 조사 중심이어야 한다.
- Planner는 가능한 접근과 추천 방향을 제시해야 한다.
- Reviewer는 리스크, 테스트 필요 지점, 하지 말아야 할 변경을 검토해야 한다.
- 구현 가능성이 이어지는 경우 마지막에 승인 요청 문장이 포함돼야 한다.

변경 사항이 없어야 한다.

```bash
git diff
```

## 3. AI Work Logging 확인

테스트 순서:

1. `/hooks`에서 hook 로드와 trust 상태를 확인한다.
2. 아무 테스트 프롬프트를 입력한다.

```text
AGENTS.md 지침이 적용됐는지 요약해줘.
```

3. Codex가 읽기 전용 도구를 하나 이상 사용하게 요청한다.

```text
현재 저장소의 최상위 파일 목록만 확인해줘.
```

4. 터미널에서 로그를 확인한다.

```bash
tail -n 5 .codex/logs/prompts.jsonl
tail -n 5 .codex/logs/tools.jsonl
tail -n 5 .codex/logs/turns.jsonl
```

정상 동작 기준:

- `prompts.jsonl`에 사용자 프롬프트 메타데이터가 기록된다.
- `tools.jsonl`에 도구 실행 전/후 메타데이터가 기록된다.
- `turns.jsonl`에 턴 종료 메타데이터가 기록된다.
- 도구 출력 전체가 과도하게 저장되지 않는다.
- `.codex/logs/`의 실제 JSONL 로그가 Git 추적 대상이 아니어야 한다.

확인 명령:

```bash
git status --short .codex/logs
```

정상이라면 로그 파일 자체가 커밋 대상으로 뜨지 않아야 한다.
