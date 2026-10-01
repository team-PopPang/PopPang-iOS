# PopPang 작업 안내

이 문서는 Codex, Claude Code 같은 AI 에이전트가 PopPang 저장소에서 작업할 때 따르는 공통 규칙이다. 반드시 지킬 규칙과 문서 길잡이만 담고, 세부 기준은 `Docs/` 아래 문서에 둔다.

## 프로젝트 요약

- PopPang은 팝업스토어 정보를 키워드 알림, 검색, 달력, 지도, 찜, 상세, 리뷰 흐름으로 제공하는 iOS 앱이다.
- SwiftUI와 TCA(The Composable Architecture)로 화면과 상태를 만들고, Tuist로 모듈별 project를 구성한다. iOS deployment target은 `17.0`이다.
- 목록 화면은 직접 만든 외부 패키지 PopPangListKit(UICollectionView 기반 선언형 목록 DSL)을 쓴다.
- 작업 대상과 판단 근거는 `Projects/` 아래 코드다. `Legacy/`와 `Docs/etc/`는 이전 구현·문서 보관본이므로 근거로 쓰지 않고 수정하지 않는다.

## 1. Plan-first Workflow

에이전트는 사용자가 구현, 수정, 리팩터링, 버그 수정, 테스트 추가를 요청해도 바로 파일을 수정하지 않는다.

모든 코드 변경 작업은 아래 순서를 따른다.

1. 기존 구조를 먼저 파악한다.
2. 변경 계획을 작성한다.
3. 리스크와 영향 범위를 명시한다.
4. 사용자의 명시적 승인을 받은 뒤에만 파일을 수정한다.

사용자가 `승인`, `진행해`, `구현해`, `수정해`처럼 명시적으로 허가하기 전까지 파일을 생성, 수정, 삭제하지 않는다.

### 승인 전 허용되는 작업

- 파일과 디렉터리 구조 확인
- `rg`, `ls`, `sed -n`, `git status`, `git diff` 등 읽기 전용 명령 실행
- 기존 코드 흐름 분석, 변경 후보 파일 목록 작성
- 테스트 전략 제안, 리스크와 영향 범위 정리

### 승인 전 금지되는 작업

- 파일 생성, 수정, 삭제, `apply_patch` 사용, 포맷터 실행
- 패키지 또는 의존성 변경
- `tuist install`, `tuist generate`, `make regen`처럼 파일을 생성하거나 갱신할 수 있는 명령 실행
- DB schema, API response, DTO, public protocol 변경
- 테스트 계획 없이 구현부터 진행

### 구현 전 계획서 형식

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

승인 후에도 계획에 없던 파일 수정, API 계약 변경, DB 변경, 모듈 의존성 변경, 대규모 리팩터링이 필요해지면 즉시 멈춘다. 변경이 필요한 이유와 대안을 설명하고 다시 승인을 받는다.

### 예외

아래 작업은 사용자가 명시적으로 요청한 경우에만 승인 없이 수행할 수 있다.

- 현재 시간 확인처럼 단순 명령 하나로 끝나는 읽기 전용 작업
- `git status`, `git diff`처럼 변경 전 상태를 확인하는 작업
- 사용자가 "바로 수정해", "계획 없이 진행해"처럼 승인 단계를 생략하라고 명시한 작업

예외에 해당해도 파괴적 명령, 대규모 변경, 외부 서비스 호출, 의존성 변경은 별도로 확인한다.

## 2. 작업 전에 확인할 문서

| 확인할 내용 | 문서 |
| --- | --- |
| 모듈 구조, 계층 책임, 의존성 방향, 새 기능 순서 | [아키텍처](Docs/architecture/architecture.md) |
| Reducer·State·Action·Effect·View 작성 규칙 | [TCA Feature 작성 규칙](Docs/architecture/tca-feature.md) |
| 화면 전환 소유권, Path·Destination | [TCA Navigation](Docs/architecture/tca-navigation.md) |
| Repository·Usecase 조립, feature-scoped client, Demo 주입 | [의존성 주입](Docs/architecture/dependency-injection.md) |
| PopPangListKit으로 목록 화면 만들기 | [PopPangListKit](Docs/architecture/poppang-listkit.md) |
| Tuist 모듈 추가, product type, ThirdParty 정책 | [모듈 구조](Docs/architecture/modules.md) |
| Tuist 설치, workspace 생성, 빌드 명령 | [Tuist 설치와 실행](Docs/development/tuist.md) |
| Swift 코드 작성 규칙 | [Swift 스타일](Docs/development/swiftstyle.md) |
| 테스트 타깃과 실행 명령 | [테스트](Docs/development/testing.md) |
| 이슈·브랜치·커밋·PR 규칙, push 전 리뷰 hook | [Git 작업 흐름](Docs/development/gitflow.md) |
| 커밋·PR의 AI 작성 표기 | [AI 작성 표기 규칙](Docs/development/ai-attribution.md) |
| 한국어 문서 윤문 | [한국어 윤문 원칙](Docs/development/korean-editing.md) · [문서 윤문 예시](Docs/development/examples/korean-editing-examples.md) |
| PR 제목·본문 작성 | [한국어 윤문 원칙](Docs/development/korean-editing.md) · [PR 작성 예시](Docs/development/examples/pr-writing-examples.md) |
| Role Prompt Workflow, 스킬, Codex 작업 로그 | [AI 작업 흐름](Docs/development/ai-workflow.md) |

위 문서는 모두 `Projects/` 코드를 기준으로 쓴다. 문서를 고칠 때도 `Projects/` 코드에서 확인한 내용만 적는다.

## 3. 아키텍처 핵심 규칙

- 앱 루트 전환(launch, onboarding, auth, register, main)은 `AppFeature`가 소유한다. 로그인 이후 탭과 탭 공통 push·fullScreen은 `MainTabFeature`가 소유한다.
- child feature는 다른 feature를 직접 조립하지 않는다. `.delegate(...)` action으로 의도만 올리고, parent가 `StackState`나 `@Presents` destination을 바꿔 화면을 전환한다.
- 화면 전환을 위한 `@escaping` closure를 새로 추가하지 않는다. 버튼 같은 UI 이벤트 closure와 SDK delegate bridge는 이 규칙과 구분한다.
- 여러 presentation은 `@Reducer enum Destination`과 `@Presents var destination` 하나로 모델링한다. 쌓이는 push는 `@Reducer enum Path`와 `StackState<Path.State>`로 모델링한다.
- 전역 세션의 source of truth는 `AppFeature.State.session`이다. child feature는 shared session을 직접 읽지 않고 필요한 사용자 값만 state로 받는다.
- TCA reducer는 `DependencyValues`로만 의존성을 받는다. feature-scoped client의 실제 구현은 `AppBootstrap`(composition root)에서 usecase로 조립해 `withDependencies`로 주입한다.
- `Domain`은 다른 프로젝트 모듈에 의존하지 않는다. DTO, Moya, SDK 타입을 `Domain`에 들이지 않는다.
- 외부 SDK 선언은 `Projects/Shared/ThirdParty/Project.swift`와 `Tuist/Package.swift`에 모은다. product type은 링크 위험이 크므로 근거 없이 바꾸지 않는다.
- `*.xcodeproj`, `*.xcworkspace`, `Derived/` 같은 Tuist 생성물은 직접 고치지 않는다.

## 4. 작업 중 판단 기준

| 상황 | 판단 기준 |
| --- | --- |
| 문서와 코드 또는 프로젝트 설정이 다르다. | 실제 코드와 설정을 기준으로 작업하고, 관련 문서도 같은 작업에서 고친다. 이번 범위에서 고칠 수 없으면 후속 작업으로 남긴다. |
| 아키텍처, 라이브러리, 빌드 명령, 팀 정책을 확인하지 못했다. | 단정하지 말고 `확인 필요`라고 적는다. 확인할 파일이나 명령도 함께 적는다. |
| 모듈 책임, navigation, DI, API·DTO 흐름, ThirdParty·Tuist 정책을 바꿨다. | 해당 `Docs/architecture/` 문서를 같은 작업에서 갱신한다. |
| API 계약, DTO, Domain entity, public protocol, DI 등록, TCA path·destination, 모듈 의존성, Tuist 설정, Info.plist·entitlements·signing을 바꾼다. | 작은 수정처럼 보여도 계획에 영향 범위를 명시하고 승인을 받는다. |
| 기능 방향, 구현 방향, 리팩터링 방향, 버그 수정 방향을 묻는다. | 구현하지 않고 Role Prompt Workflow를 적용한다. |
| 커밋 메시지나 PR 본문을 쓴다. | [Git 작업 흐름](Docs/development/gitflow.md)을 따른다. PR 제목은 이슈 제목과 같게 쓴다. AI 공동 작성자 트레일러, 생성 문구, 세션 링크를 넣지 않는다. |
| 한국어 문서나 PR 설명을 쓰거나 다듬는다. | [한국어 윤문 원칙](Docs/development/korean-editing.md)을 따른다. 원문의 의미·사실·보호 구간을 유지하고, `Projects/` 코드로 확인한 내용만 쓴다. |
| push 전 리뷰 hook이 설정되어 있지 않다. | `git config core.hooksPath`가 `.githooks`가 아니고 `git config project-docs.gitHooks`가 `declined`가 아니면, 작업을 시작할 때 사용자에게 설정할지 한 번 묻는다. 승낙하면 `npx --yes --package=github:indextrown/codex-skillbook -- project-docs hooks ios-uikit --apply`를 실행한다. 거절하면 `git config project-docs.gitHooks declined`로 기록하고 다시 묻지 않는다. |
| push했는데 hook이 `FAIL`을 냈다. | 지적된 문제를 고치고 다시 push한다. `git push --no-verify`는 사용자가 요청할 때만 쓴다. |

## 5. Role Prompt Workflow와 스킬

서브에이전트는 기본으로 사용하지 않는다. 기능·구현·리팩터링·버그 수정의 방향을 묻는 요청에는 아래 프롬프트를 순서대로 적용하고 파일을 수정하지 않는다.

1. `.codex/prompts/researcher.md`
2. `.codex/prompts/planner.md`
3. `.codex/prompts/reviewer.md`

```text
## Researcher 관점

## Planner 관점

## Reviewer 관점

## 최종 추천 방향
```

필요하면 마지막에 승인 요청 문장을 붙인다.

| 스킬 (`.agents/skills/`) | 사용하는 요청 |
| --- | --- |
| `planning-pipeline` | "계획세워줘", "방향성 잡아줘", "구현 전에 검토해줘", "수정 방향 먼저 정리해줘" |
| `auto-commit-push` | "커밋해", "커밋하고 푸시해", "자동 커밋", "push까지 해줘". push는 명시적으로 요청할 때만 한다. |
| `auto-pr` | "PR 올려줘", "pr 생성해", "자동 PR", "풀리퀘 만들어줘". PR 생성 요청에는 현재 브랜치 push가 포함된다. |
| `tca-refactor` | 기존 feature를 TCA로 옮기는 작업 |

요청이 스킬에 해당하면 해당 `SKILL.md`를 읽고 따른다. 세부 절차와 Codex 작업 로그 규칙은 [AI 작업 흐름](Docs/development/ai-workflow.md)에 있다.

## 6. 열람·커밋 금지 파일

- 열람하거나 출력하지 않는다: `.env`, `*.xcconfig`, `GoogleService-Info.plist`, 인증키·토큰·비밀번호가 담긴 파일
- 커밋하지 않는다: 위 파일, `.codex/logs/*.jsonl`, `.DS_Store`, Xcode·Tuist 생성물(`*.xcodeproj/`, `*.xcworkspace/`, `**/Derived/`, `.tuist/`, `Tuist/.build/`), 빌드 산출물(`DerivedData/`, `*.ipa`, `*.dSYM`), `fastlane/metadata/`, `fastlane/report.xml`

## 7. 작업 완료 전 확인

- [ ] 변경한 동작과 관련 문서의 설명이 일치한다.
- [ ] 확인하지 못한 내용에 `확인 필요`와 확인 대상을 남겼다.
- [ ] 프로젝트에 맞는 빌드·테스트를 실행했고, 실행하지 못했다면 이유를 남겼다.
- [ ] 금지 파일이 변경 사항에 섞이지 않았다.
- [ ] 커밋 메시지와 PR 본문에 AI 공동 작성자·생성 문구·세션 링크가 없다.
