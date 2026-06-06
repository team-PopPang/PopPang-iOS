# AGENTS.md

이 문서는 PopPang 저장소에서 Codex가 작업할 때 따르는 프로젝트 운영 규칙이다.

## 0. Codex CLI 시작 시 AGENTS.md 로딩 보장

Codex CLI가 이 문서를 항상 읽도록 하려면 `AGENTS.md`를 저장소 루트에 두고, Codex CLI를 저장소 루트 기준으로 시작한다.

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

Codex CLI 실행은 목적에 따라 아래 세 가지 프로필로 나눈다.

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

- `AGENTS.md`는 행동 지침이며, 파일 수정과 명령 실행의 실제 통제는 sandbox와 approval policy 설정을 함께 사용해야 더 안전하다.
- Codex는 빈 지침 파일을 무시할 수 있으므로 이 파일은 항상 실제 내용을 유지한다.
- 지침 파일이 너무 커지면 일부 내용이 잘릴 수 있으므로 운영 규칙은 짧고 명확하게 유지한다.

## 1. Plan-first Workflow

Codex는 사용자가 구현, 수정, 리팩터링, 버그 수정, 테스트 추가를 요청하더라도 즉시 파일을 수정하지 않는다.

모든 코드 변경 작업은 아래 순서를 따른다.

1. 기존 구조를 먼저 파악한다.
2. 변경 계획을 작성한다.
3. 리스크와 영향 범위를 명시한다.
4. 사용자의 명시적 승인을 받은 뒤에만 파일을 수정한다.

사용자가 `승인`, `진행해`, `구현해`, `수정해`처럼 명시적으로 허가하기 전까지 Codex는 파일을 생성, 수정, 삭제하지 않는다.

### 승인 전 허용되는 작업

승인 전에는 읽기 전용 작업만 수행한다.

허용되는 작업:

- 파일과 디렉터리 구조 확인
- `rg`, `ls`, `sed -n`, `git status`, `git diff` 등 읽기 전용 명령 실행
- 기존 코드 흐름 분석
- 변경 후보 파일 목록 작성
- 테스트 전략 제안
- 리스크와 영향 범위 정리

금지되는 작업:

- 파일 생성, 수정, 삭제
- `apply_patch` 사용
- 포맷터 실행
- 패키지 또는 의존성 변경
- `tuist generate`, `make regen`처럼 파일을 생성하거나 갱신할 수 있는 명령 실행
- DB schema, API response, DTO, public protocol 변경
- 테스트 계획 없이 구현부터 진행

### 구현 전 계획서 형식

코드 변경 전 Codex는 아래 항목을 포함한 계획을 먼저 제시한다.

- 요청 요약
- 현재 구조 파악 결과
- 변경 예정 파일
- 변경하지 않을 파일과 범위
- API, DB, 라우팅, DI, 모듈 의존성 영향 여부
- 테스트 계획
- 예상 리스크
- 승인 후 작업 순서

계획서 마지막에는 반드시 아래 문장을 포함한다.

```text
위 계획으로 진행해도 될까요? 승인 전까지 파일은 수정하지 않겠습니다.
```

### 계획 범위 이탈 시 중단

승인 후 작업 중에도 계획에 없던 파일 수정, API 계약 변경, DB 변경, 모듈 의존성 변경, 대규모 리팩터링이 필요해지면 즉시 작업을 멈춘다.

Codex는 변경 필요 이유와 대안을 설명하고 사용자에게 다시 승인을 받아야 한다.

### 예외

아래 작업은 사용자가 명시적으로 요청한 경우에만 승인 없이 수행할 수 있다.

- 현재 시간 확인처럼 단순 명령 하나로 끝나는 읽기 전용 작업
- `git status`, `git diff`처럼 변경 전 상태를 확인하는 작업
- 사용자가 "바로 수정해", "계획 없이 진행해"처럼 승인 단계를 생략하라고 명시한 작업

단, 예외에 해당하더라도 파괴적 명령, 대규모 변경, 외부 서비스 호출, 의존성 변경은 별도 확인 후 진행한다.

### 공식 문서

- OpenAI Codex AGENTS.md: https://developers.openai.com/codex/guides/agents-md
- OpenAI Codex approvals & security: https://developers.openai.com/codex/agent-approvals-security

## 2. Role Prompt Workflow

서브에이전트는 기본으로 사용하지 않는다.

사용자가 기능 방향성, 구현 방향, 리팩터링 방향, 버그 수정 방향을 요청하면 Codex는 바로 구현하지 않고 아래 Markdown 프롬프트를 순서대로 적용한다.

1. `.codex/prompts/researcher.md`
2. `.codex/prompts/planner.md`
3. `.codex/prompts/reviewer.md`

이 방식은 공식 Custom Prompts slash command가 아니라 저장소 내부에서 공유하는 역할별 프롬프트 규칙이다.

### 적용 조건

아래와 같은 요청에는 Role Prompt Workflow를 먼저 적용한다.

- "A 기능 방향성을 제시해줘"
- "A 기능을 어떻게 구현할지 방향부터 잡아줘"
- "이 버그를 고치기 전에 접근 방법을 정리해줘"
- "리팩터링 방향을 먼저 제안해줘"
- "구현하지 말고 계획만 세워줘"

### 진행 순서

1. Researcher 관점으로 기존 구조, 관련 파일, 현재 제약을 정리한다.
2. Planner 관점으로 가능한 접근 방법과 추천 방향을 제시한다.
3. Reviewer 관점으로 리스크, 테스트 필요 지점, 하지 말아야 할 변경을 검토한다.
4. 최종 추천 방향과 다음 단계를 요약한다.

이 단계에서는 파일을 생성, 수정, 삭제하지 않는다.

### 출력 형식

Role Prompt Workflow를 적용할 때는 아래 형식으로 답한다.

```text
## Researcher 관점

## Planner 관점

## Reviewer 관점

## 최종 추천 방향
```

마지막에는 필요한 경우 아래 문장을 포함한다.

```text
위 계획으로 진행해도 될까요? 승인 전까지 파일은 수정하지 않겠습니다.
```

### 역할별 프롬프트 관리

- `researcher.md`는 조사 전용이다. 구현 계획을 확정하지 않는다.
- `planner.md`는 계획 전용이다. 파일을 수정하지 않는다.
- `reviewer.md`는 검토 전용이다. 코드를 직접 수정하지 않는다.
- 역할별 프롬프트를 수정해도 실행 중인 Codex 세션에는 즉시 반영되지 않을 수 있으므로 새 세션에서 다시 확인한다.

## 3. AI Work Logging

Codex 작업은 재현성, 디버깅 가능성, 오류 원인 추적을 위해 최소 로그를 남긴다.

로그는 Hook 기반으로 기록한다.

기록 대상:

- 사용자 프롬프트
- 도구 실행 시도
- 도구 실행 결과 메타데이터
- 턴 종료 메타데이터

로그 위치:

- `.codex/logs/prompts.jsonl`
- `.codex/logs/tools.jsonl`
- `.codex/logs/turns.jsonl`

운영 규칙:

- `.codex/logs/`는 Git에 커밋하지 않는다.
- 초기 Hook은 기록만 수행하고 작업을 차단하지 않는다.
- 도구 출력 전체는 저장하지 않는다.
- 비밀키, 토큰, 개인정보가 포함될 수 있으므로 로그 공유 전 반드시 확인한다.
- Hook 변경 후에는 Codex를 재시작하고 `/hooks`에서 hook을 확인 및 trust한다.
- 위험 명령 차단, 외부 서버 전송, 자동 요약은 별도 단계에서 도입한다.

Hook 파일:

- `.codex/hooks.json`: Codex hook 이벤트와 실행할 스크립트를 연결하는 설정 파일이다.
- `.codex/hooks/log_user_prompt.py`: `UserPromptSubmit` 이벤트에서 사용자 프롬프트를 `.codex/logs/prompts.jsonl`에 기록한다.
- `.codex/hooks/log_pre_tool_use.py`: `PreToolUse` 이벤트에서 Codex가 실행하려는 도구 이름과 명령 메타데이터를 `.codex/logs/tools.jsonl`에 기록한다.
- `.codex/hooks/log_post_tool_use.py`: `PostToolUse` 이벤트에서 도구 실행 결과 메타데이터를 `.codex/logs/tools.jsonl`에 기록한다.
- `.codex/hooks/log_stop.py`: `Stop` 이벤트에서 한 턴의 종료 메타데이터를 `.codex/logs/turns.jsonl`에 기록한다.
- `.codex/logs/.gitignore`: 실제 JSONL 로그가 Git에 커밋되지 않도록 `.codex/logs/` 안의 로그 파일을 무시한다.

공식 문서:

- OpenAI Codex hooks: https://developers.openai.com/codex/hooks
- OpenAI Codex config reference: https://developers.openai.com/codex/config-reference#configtoml
