# PopPang AI 작업 흐름

이 문서는 Codex, Claude Code 같은 AI 에이전트가 PopPang에서 작업하는 절차를 자세히 설명한다. 반드시 지킬 규칙은 루트 [`AGENTS.md`](../../AGENTS.md)에 있고, 이 문서는 그 배경과 세부 절차를 다룬다.

## 목차

- [Plan-first Workflow](#plan-first-workflow)
- [Role Prompt Workflow](#role-prompt-workflow)
- [프로젝트 스킬](#프로젝트-스킬)
- [에이전트별 차이](#에이전트별-차이)
- [AI 작업 로그](#ai-작업-로그)
- [공식 문서](#공식-문서)

## Plan-first Workflow

코드 변경 요청을 받아도 바로 파일을 고치지 않는다. 구조 파악 → 계획 → 리스크 정리 → 사용자 승인 → 수정 순서를 지킨다.

### 승인으로 보는 표현

`승인`, `진행해`, `구현해`, `수정해`처럼 수정을 명시적으로 허가하는 표현을 승인으로 본다. 허가인지 분명하지 않으면 다시 확인한다.

### 승인 전에 할 수 있는 작업

| 허용 | 금지 |
| --- | --- |
| 파일·디렉터리 구조 확인 | 파일 생성, 수정, 삭제 |
| `rg`, `ls`, `sed -n`, `git status`, `git diff` 같은 읽기 전용 명령 | `apply_patch`, 포맷터 실행 |
| 기존 코드 흐름 분석, 변경 후보 파일 목록 작성 | 패키지·의존성 변경 |
| 테스트 전략과 리스크 정리 | `tuist generate`, `make regen`처럼 파일을 생성·갱신하는 명령 |
| | DB schema, API response, DTO, public protocol 변경 |

### 계획서 형식

```text
- 요청 요약
- 현재 구조 파악 결과
- 변경 예정 파일
- 변경하지 않을 파일과 범위
- API, DB, 라우팅, DI, 모듈 의존성 영향 여부
- 테스트 계획
- 예상 리스크
- 승인 후 작업 순서

위 계획으로 진행해도 될까요? 승인 전까지 파일은 수정하지 않겠습니다.
```

### 승인 뒤에도 멈추는 경우

계획에 없던 파일 수정, API 계약 변경, DB 변경, 모듈 의존성 변경, 대규모 리팩터링이 필요해지면 작업을 멈춘다. 필요한 이유와 대안을 설명하고 다시 승인을 받는다.

### 예외

아래 작업은 사용자가 요청하면 승인 절차 없이 해도 된다.

- 현재 시간 확인처럼 명령 하나로 끝나는 읽기 전용 작업
- `git status`, `git diff`처럼 변경 전 상태를 확인하는 작업
- 사용자가 "바로 수정해", "계획 없이 진행해"처럼 승인 단계를 생략하라고 한 작업

예외라도 파괴적 명령, 대규모 변경, 외부 서비스 호출, 의존성 변경은 따로 확인한다.

## Role Prompt Workflow

기능 방향, 구현 방향, 리팩터링 방향, 버그 수정 방향을 묻는 요청에는 구현하지 않고 세 관점으로 검토한다. 서브에이전트는 기본으로 쓰지 않는다.

| 순서 | 프롬프트 | 역할 |
| --- | --- | --- |
| 1 | `.codex/prompts/researcher.md` | 기존 구조, 관련 파일, 제약을 조사한다. 계획을 확정하지 않는다. |
| 2 | `.codex/prompts/planner.md` | 접근 방법을 비교하고 추천 방향, 변경 범위, 테스트 계획을 세운다. |
| 3 | `.codex/prompts/reviewer.md` | 리스크, 테스트 누락, 하지 말아야 할 변경을 검토한다. |

적용하는 요청 예:

- "A 기능 방향성을 제시해줘"
- "이 버그를 고치기 전에 접근 방법을 정리해줘"
- "리팩터링 방향을 먼저 제안해줘"
- "구현하지 말고 계획만 세워줘"

출력 형식:

```text
## Researcher 관점

## Planner 관점

## Reviewer 관점

## 최종 추천 방향
```

세 프롬프트는 [아키텍처](../architecture/architecture.md)를 기준 맥락으로 읽는다. 프롬프트를 고쳐도 이미 실행 중인 세션에는 반영되지 않을 수 있으므로 새 세션에서 확인한다.

## 프로젝트 스킬

스킬은 `.agents/skills/<name>/SKILL.md`에 있다.

| 스킬 | 사용하는 요청 | 핵심 규칙 |
| --- | --- | --- |
| `planning-pipeline` | "계획세워줘", "방향성 잡아줘", "구현 전에 검토해줘" | Role Prompt Workflow를 순서대로 적용하고 파일을 고치지 않는다. |
| `auto-commit-push` | "커밋해", "커밋하고 푸시해", "push까지 해줘" | `type: 한글 설명` 형식으로 커밋한다. push는 명시적으로 요청할 때만 한다. |
| `auto-pr` | "PR 올려줘", "pr 생성해", "풀리퀘 만들어줘" | `.github/PULL_REQUEST_TEMPLATE.md`와 git log·diff로 본문을 쓰고 `gh pr create`로 게시한다. PR 생성 요청에는 현재 브랜치 push가 포함된다. |
| `tca-refactor` | 기존 feature를 TCA로 옮기는 작업 | [TCA Navigation](../architecture/tca-navigation.md) 기준을 따른다. |

커밋·PR 세부 규칙은 [Git 작업 흐름](gitflow.md)을 따른다.

## 에이전트별 차이

| 항목 | Codex | Claude Code |
| --- | --- | --- |
| 작업 지침 | 루트 `AGENTS.md`를 자동으로 읽는다. | 루트 `CLAUDE.md`가 `@AGENTS.md`로 같은 지침을 불러온다. |
| 프로젝트 스킬 | `.agents/skills/`를 repo-scoped skill로 자동 감지한다. | `.agents/skills/`를 자동으로 불러오지 않는다. 요청이 스킬에 해당하면 `SKILL.md`를 직접 읽고 따른다. |
| 작업 로그 hook | `.codex/hooks.json`이 로그를 남긴다. | `.codex/hooks.json`을 쓰지 않는다. |
| 운영 검증 체크리스트 | [`.codex/guideline.md`](../../.codex/guideline.md) | 해당 없음 |

## AI 작업 로그

Codex 작업은 재현과 오류 추적을 위해 hook으로 최소 로그를 남긴다.

| 파일 | 이벤트 | 기록 대상 |
| --- | --- | --- |
| `.codex/hooks/log_user_prompt.py` | `UserPromptSubmit` | 사용자 프롬프트 → `.codex/logs/prompts.jsonl` |
| `.codex/hooks/log_pre_tool_use.py` | `PreToolUse` | 실행하려는 도구 이름과 명령 메타데이터 → `.codex/logs/tools.jsonl` |
| `.codex/hooks/log_post_tool_use.py` | `PostToolUse` | 도구 실행 결과 메타데이터 → `.codex/logs/tools.jsonl` |
| `.codex/hooks/log_stop.py` | `Stop` | 턴 종료 메타데이터 → `.codex/logs/turns.jsonl` |

운영 규칙:

- `.codex/logs/`는 `.gitignore`에 들어 있고 커밋하지 않는다.
- hook은 기록만 하고 작업을 막지 않는다. 도구 출력 전체는 저장하지 않는다.
- 로그에는 비밀키, 토큰, 개인정보가 들어갈 수 있으므로 공유하기 전에 확인한다. PR 본문에 로그 원문을 붙이지 않는다.
- hook을 바꾼 뒤에는 Codex를 다시 시작하고 `/hooks`에서 확인하고 trust한다.
- 위험 명령 차단, 외부 서버 전송, 자동 요약은 별도 단계에서 도입한다.

## 공식 문서

- [OpenAI Codex AGENTS.md](https://developers.openai.com/codex/guides/agents-md)
- [OpenAI Codex approvals & security](https://developers.openai.com/codex/agent-approvals-security)
- [OpenAI Codex hooks](https://developers.openai.com/codex/hooks)
- [OpenAI Codex config reference](https://developers.openai.com/codex/config-reference#configtoml)
- [Claude Code memory (CLAUDE.md)](https://code.claude.com/docs/en/memory)
