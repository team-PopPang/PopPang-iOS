# Current Architecture

이 문서는 PopPang의 현재 활성 코드 구조와 TCA migration 시 지켜야 할 기준선을 빠르게 복원하기 위한 reference다.

코드와 이 문서가 충돌하면 현재 루트 `Projects/*` 코드를 우선한다. 구조 이해가 바뀌면 이 문서를 함께 갱신한다.

## 활성 코드 기준

- 실제 구현 대상: 루트 `Projects/*`
- 비교용 reference: `V1/*`
- root workspace: 현재 `Workspace.swift`는 `Projects/App`, `Projects/Features`, `Projects/Domain`, `Projects/Data`, `Projects/Shared`를 포함한다.
- `Projects/Coordinator`는 제거 완료된 legacy 모듈이며 workspace에 재도입하지 않는다.

즉 현재 작업은 기본적으로 `V1/*`가 아니라 루트 `Projects/*`에 반영한다.

## 최상위 구조

```text
Projects
├── App
├── Domain
├── Data
├── Features
│   ├── AdFeature
│   ├── AlertFeature
│   ├── AuthFeature
│   ├── CalendarFeature
│   ├── FavoritesFeature
│   ├── HomeFeature
│   ├── MapFeature
│   ├── OnboardingFeature
│   ├── PopupDetailFeature
│   ├── PopupRequestFeature
│   ├── PopupRequestManagementFeature
│   ├── ProfileFeature
│   ├── ReviewFeature
│   └── SearchFeature
└── Shared
    ├── Core
    ├── DSKit
    └── ThirdParty
```

## 아키텍처 기준

### App

- SDK 초기화
- repository/usecase live 조립
- `DIContainer` 등록
- `AppFeature` root store 생성으로 전환 예정
- root/auth/main TCA navigation 소유 예정

핵심 파일:

- `Projects/App/Sources/PopPangApp.swift`
- `Projects/App/Sources/AppCore/AppBootstrap.swift`
- `Projects/App/Sources/AppCore/AppDependencyRegistry.swift`

### Navigation

- `RootCoordinator -> MainTabCoordinator -> FeatureCoordinator` 구조는 제거 완료되었다.
- 새 navigation은 `Docs/tca-navigation-guidelines.md`의 TCA tree-based / stack-based 기준을 따른다.
- active main flow는 App 모듈의 `MainTabFeature`가 `StackState`와 `@Presents` destination으로 소유한다.
- 탭 root view는 중첩 `NavigationStack`을 만들지 않는다.
- feature는 화면 전환용 escaping closure 대신 reducer delegate action으로 navigation intent를 올린다.
- path/destination state에는 `Binding`, `View`, 무거운 closure를 넣지 않는다.

### Features

- 현재 기본 상태관리는 TCA와 Compound가 공존하는 점진 전환 상태다.
- TCA migration은 feature 단위 vertical slice로 진행 중이다.
- feature는 `Domain`, `Core`, `DSKit`, `ThirdParty`를 주로 의존한다.
- feature 간 직접 import는 예외를 줄이고 parent TCA reducer 조립을 우선한다.

### Domain

- Entity
- Repository protocol
- Usecase protocol / implementation
- `DIContainer`와 `@Dependency`

주의:

- 외부 SDK나 DTO를 Domain에 넣지 않는다.
- public protocol 변경은 Feature/Data/App에 파급된다.

### Data

- Repository protocol 구현
- Moya API target
- DTO 및 mapping
- 소셜 로그인 SDK 구현

### Shared

- `Core`: network, storage, shared foundation utilities
- `DSKit`: design system
- `ThirdParty`: 외부 SDK link hub

## 현재 TCA 전환 상태

### 이미 `@Reducer`가 들어간 영역

- `Projects/App/Sources/AppCore/Navigation/AppFeature.swift`
- `Projects/App/Sources/AppCore/Navigation/MainTabFeature.swift`
- `Projects/Features/AuthFeature/Sources/Presentation/AuthFeature.swift`
- `Projects/Features/AuthFeature/Sources/Presentation/RegisterFlowFeature.swift`
- `Projects/Features/CalendarFeature/Sources/Presentation/CalendarFeature.swift`
- `Projects/Features/FavoritesFeature/Sources/Presentation/FavoritesFeature.swift`
- `Projects/Features/OnboardingFeature/Sources/Presentation/OnboardingFeature.swift`
- `Projects/Features/HomeFeature/Sources/Presentation/HomeFeatureReducer.swift`
- `Projects/Features/HomeFeature/Sources/Presentation/ComingPopupDetailReducer.swift`
- `Projects/Features/ProfileFeature/Sources/Presentation/ProfileFeature.swift`
- `Projects/Features/PopupDetailFeature/Sources/Presentation/PopupDetailFeatureReducer.swift`

### 아직 `@Compound` 중심인 주요 영역

- `AlertFeature`
- `MapFeature`
- `PopupRequestFeature`
- `PopupRequestManagementFeature`
- `ReviewFeature`
- `SearchFeature`

## 현재 TCA 패턴

현재 reducer 예시는 아래 패턴을 사용한다.

1. `@Reducer` + `@ObservableState`
2. feature 전용 `Client` struct 정의
3. `DIContainer.shared.resolve(...)`를 `DependencyValues` bridge 뒤에 숨김
4. view는 `StoreOf<Reducer>`를 `@State`로 보유
5. navigation은 TCA `Destination` / `Path` 중심으로 전환 중

예:

- `HomeFeatureReducer`는 `HomePopupClient`를 통해 `PopupUsecaseProtocol`을 감싼다.
- `PopupDetailFeatureReducer`는 `PopupDetailClient`를 통해 `PopupUsecaseProtocol`, `AdminUsecaseProtocol`을 감싼다.

## Migration 시 우선 지킬 원칙

1. Coordinator 구조는 제거 완료된 legacy 구조다. 새 navigation 작업에서는 재도입하지 않는다.
2. `PopupUsecaseProtocol` 같은 넓은 public contract를 초반에 분리하지 않는다.
3. reducer에는 비즈니스 상태와 effect 타이밍에 필요한 상태만 둔다.
4. 순수 UI 임시 상태는 view local state로 남겨도 된다.
5. feature 이동은 delegate action으로 parent reducer에 올린다.
6. tree-based navigation은 `@Reducer enum Destination`과 단일 `@Presents var destination`으로 모델링한다.
7. stack-based navigation은 `@Reducer enum Path`와 `StackState<Path.State>`로 모델링한다.
8. `V1/*`는 원형 비교용일 뿐, 수정 대상으로 가정하지 않는다.

## 링크/모듈 정책

- feature 모듈은 기본적으로 `.staticFramework`
- `ThirdParty`, `Core`, `DSKit`, `Domain`, `Data`는 현재 공유 경계로 유지
- `Coordinator`는 제거 완료된 legacy 경계이며 App 의존성에 재추가하지 않는다.
- 외부 SDK 선언은 `Projects/Shared/ThirdParty/Project.swift` 기준으로 본다.

TCA migration 중에도 이 정책은 그대로 유지하는 것을 기본값으로 삼는다.
