# AGENTS.md

이 문서는 PopPang 저장소에서 Codex가 작업할 때 따르는 프로젝트 운영 규칙이다.

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

계획, 방향성, 구현 전 검토 요청에는 공식 repo-scoped skill 경로인 `.agents/skills/planning-pipeline`을 우선 사용한다. 이 스킬은 아래 Markdown 프롬프트를 순서대로 읽고 적용한다.

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

### 프로젝트 전용 스킬

- `.agents/skills/planning-pipeline`: PopPang 전용 계획/방향성 검토 워크플로우다.
- 사용자가 "계획세워줘", "방향성 잡아줘", "구현 전에 검토해줘", "수정 방향 먼저 정리해줘"처럼 요청하면 이 스킬의 `SKILL.md`를 읽고 `.codex/prompts/researcher.md`, `.codex/prompts/planner.md`, `.codex/prompts/reviewer.md`를 순서대로 적용한다.
- `.agents/skills/auto-commit-push`: PopPang 전용 git 커밋 및 푸시 워크플로우다.
- 사용자가 "커밋해", "커밋하고 푸시해", "자동 커밋", "push까지 해줘"처럼 요청하면 이 스킬의 `SKILL.md`를 읽고 따른다.
- 커밋 메시지는 `feat`, `chore`, `docs`, `fix`, `refactor`, `ci` 중 하나와 한글 설명을 사용한다.
- push는 사용자가 명시적으로 요청한 경우에만 수행한다.
- `.agents/skills/auto-pr`: PopPang 전용 GitHub Pull Request 자동 작성 및 게시 워크플로우다.
- 사용자가 "PR 올려줘", "pr 생성해", "자동 PR", "풀리퀘 만들어줘"처럼 요청하면 이 스킬의 `SKILL.md`를 읽고 `.github/PULL_REQUEST_TEMPLATE.md`, git log/diff, 기존 PR 문체를 바탕으로 PR 제목과 본문을 작성한 뒤 `gh pr create`로 게시한다.
- PR 생성 전에는 working tree, 현재 브랜치, 원격 push 상태, 중복 PR, 관련 이슈 번호, 금지 파일 포함 여부를 확인한다.
- auto-pr에서 PR 생성 요청은 현재 브랜치를 원격에 게시하는 작업을 포함한다.
- `.env`, `*.xcconfig`, `GoogleService-Info.plist`, `.codex/logs/*.jsonl`, Xcode/Tuist 생성물, 빌드 산출물, 인증키/토큰/비밀번호는 커밋하지 않는다.

## 3. TCA Navigation Migration Direction

PopPang은 Coordinator 패턴을 제거하고 TCA navigation을 기준 구조로 전환한다.

현재 코드에 `Projects/Coordinator` 모듈, `RootCoordinator`, `MainTabCoordinator`, feature coordinator, 화면 전환용 escaping closure가 남아 있어도 새 작업에서는 이를 확장하지 않는다. 기존 coordinator는 제거 대상이며, 새 화면 전환은 TCA reducer state/action으로 모델링한다.

자세한 기준은 `Docs/tca-navigation-guidelines.md`를 먼저 읽는다.

### 기본 방향

- 앱 루트 전환은 `AppFeature`가 소유한다.
- 인증/온보딩/회원가입 흐름은 `AuthFlowFeature`가 소유한다.
- 메인 탭과 탭 공통 push/fullScreen/sheet 흐름은 `MainTabFeature`가 소유한다.
- feature는 다른 feature를 직접 조립하지 않고 delegate action으로 intent만 올린다.
- parent feature가 `StackState` 또는 `@Presents` destination을 변경해 실제 화면 전환을 수행한다.
- 화면 전환을 위해 `@escaping` closure를 새로 추가하지 않는다.
- SwiftUI view 내부의 버튼/컴포넌트 이벤트 closure와 UIKit/SDK delegate bridge는 화면 전환용 escaping closure와 구분한다.

### Tree-based Navigation

sheet, fullScreenCover, popover, alert, confirmationDialog, root/auth 단계처럼 동시에 하나만 활성화되어야 하는 화면은 tree-based navigation을 사용한다.

여러 destination이 가능한 경우 여러 optional을 State에 나열하지 않는다. 아래처럼 `@Reducer enum Destination`을 따로 두고 State에는 단일 `@Presents var destination`만 둔다.

```swift
@Reducer
struct InventoryFeature {
    @Reducer
    enum Destination {
        case addItem(AddFeature)
        case detailItem(DetailFeature)
        case editItem(EditFeature)
    }

    @ObservableState
    struct State {
        @Presents var destination: Destination.State?
    }

    enum Action {
        case destination(PresentationAction<Destination.Action>)
    }
}
```

### Stack-based Navigation

popup detail처럼 push가 누적되거나 관련 상세로 다시 진입할 수 있는 drill-down 흐름은 stack-based navigation을 사용한다.

stack destination은 parent feature 안의 `@Reducer enum Path`로 정의하고, parent State가 `StackState<Path.State>`를 소유한다. child feature가 parent의 `Path.State`를 직접 알도록 만들지 않는다. child는 `.delegate(...)` action을 올리고 parent가 `path.append(...)`를 결정한다.

### Reducer Case Ordering

reducer의 `switch action`은 읽는 순서를 일정하게 유지한다.

1. binding, lifecycle, task
2. 일반 상태 변경 action
3. async response action
4. child feature action과 delegate action
5. navigation action: `path`, `destination`, dismiss

상태 변경과 화면 전환이 섞이면 먼저 상태 변경 case를 모으고, 그 다음 화면 전환 case를 둔다.

### Target Module Shape

장기 목표 구조는 아래 방향을 따른다. 실제 폴더 분리는 점진적으로 진행한다.

```text
PopPang
├─ AppFeature
│  ├─ AuthFlowFeature
│  │  ├─ OnboardingFeature
│  │  ├─ LoginFeature
│  │  └─ SignupFeature
│  └─ MainTabFeature
│     ├─ HomeFeature
│     ├─ CalendarFeature
│     ├─ MapFeature
│     ├─ FavoriteFeature
│     └─ ProfileFeature
├─ SharedFeature
└─ Shared
   ├─ Models
   ├─ Clients
   └─ Caches
```

현재 `Domain`의 entity/usecase/repository 계약은 즉시 `Shared`로 옮기지 않는다. 먼저 TCA navigation ownership과 escaping routing 제거를 안정화한 뒤, `Shared.Models`, `Shared.Clients`, `Shared.Caches` 분리를 별도 계획으로 진행한다.

## 4. AI Work Logging

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
- 루트 `.gitignore`: 실제 JSONL 로그가 Git에 커밋되지 않도록 `.codex/logs/` 전체를 무시한다.

공식 문서:

- OpenAI Codex hooks: https://developers.openai.com/codex/hooks
- OpenAI Codex config reference: https://developers.openai.com/codex/config-reference#configtoml
