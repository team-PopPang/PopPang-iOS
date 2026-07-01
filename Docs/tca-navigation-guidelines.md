# TCA Navigation Guidelines

이 문서는 PopPang의 Coordinator 제거와 TCA navigation 전환 기준이다.

코드와 문서가 충돌하면 현재 코드를 먼저 확인하되, 새 navigation 작업은 이 문서의 방향을 따른다.

## 결정 사항

- Coordinator 패턴은 제거 완료된 legacy 구조다.
- `Projects/Coordinator` 모듈은 workspace에서 제거되었고 새 기능에서 재도입하지 않는다.
- 화면 전환용 `@escaping` closure는 제거 대상이다.
- 새 화면 전환은 TCA state/action/reducer로 모델링한다.
- tree-based navigation과 stack-based navigation을 함께 사용한다.
- feature는 다른 feature를 직접 조립하지 않고 delegate action으로 intent만 올린다.
- 전역 세션 상태의 source of truth는 `AppFeature.session`이다.
- 현재 로그인 사용자는 `AppFeature.session.user`로 표현한다.
- `MainTabFeature`는 shared `session`을 child feature에 전달하고, 탭 로컬 navigation state를 소유한다.
- direct scope가 가능한 feature는 shared `session`을 직접 읽거나 필요한 값을 projection해서 reducer/state에 주입한다.
- 현재 `HomeFeature`는 shared `session`을 직접 읽고 홈 로컬 상태를 feature state가 소유한다.
- legacy feature는 당분간 `SessionContext` 또는 primitive 값을 view init으로 주입한다.
- 현재 `Calendar`, `Map`, `Favorites`, `Profile`은 `*LegacyBridgeFeature`가 session-derived primitive를 만들어 legacy view로 넘긴다.

## 용어

### 화면 전환용 escaping closure

상위 coordinator나 parent view에 화면 전환을 요청하기 위해 feature view initializer에 전달하던 closure를 말한다.

예:

```swift
HomeFeatureView(
    onSelectPopup: { userUuid, popup in
        coordinator.push(.popupDetail(userUuid: userUuid, popup: popup))
    }
)
```

이 패턴은 제거 대상이다. TCA 전환 후에는 view가 store action을 보내고 reducer가 state를 변경한다.

### UI 이벤트 closure

작은 view component가 버튼 탭, toggle, text field commit 같은 UI 이벤트를 부모 view에 전달하기 위해 쓰는 closure다.

예:

```swift
PopupCard(
    onTap: { store.send(.popupTapped(popup)) },
    onToggleLike: { store.send(.likeButtonTapped(popup)) }
)
```

이 closure는 화면 전환용 closure가 아니다. 단, 이 closure 안에서 직접 navigation state를 변경하지 않고 store action을 보내는 것을 기본으로 한다.

### SDK delegate bridge

Naver map marker 선택, notification callback, UIKit delegate처럼 외부 SDK를 SwiftUI/TCA로 연결하기 위한 closure다. 이는 제거 대상과 구분한다. 가능한 경우 client dependency나 adapter로 감싸 reducer action으로 들어오게 만든다.

## Tree-based Navigation

tree-based navigation은 optional state와 enum state로 화면 표시 여부를 모델링한다.

PopPang에서 tree-based navigation을 쓰는 경우:

- 앱 root 전환: launch, auth, main
- auth flow 단계: onboarding, login, signup
- sheet
- fullScreenCover
- popover
- alert
- confirmationDialog
- 동시에 하나만 활성화되어야 하는 destination

### Destination 규칙

여러 destination이 가능한 경우 State에 optional을 여러 개 두지 않는다.

피해야 하는 형태:

```swift
@ObservableState
struct State {
    @Presents var search: SearchFeature.State?
    @Presents var setting: SettingFeature.State?
    @Presents var alert: AlertState<Action.Alert>?
}
```

권장 형태:

```swift
@Reducer
struct MainTabFeature {
    @Reducer
    enum Destination {
        case search(SearchFeature)
        case setting(SettingFeature)
        case alert(AlertFeature)
    }

    @ObservableState
    struct State {
        @Presents var destination: Destination.State?
    }

    enum Action {
        case destination(PresentationAction<Destination.Action>)
    }

    var body: some ReducerOf<Self> {
        Reduce { state, action in
            switch action {
            case .destination:
                return .none
            }
        }
        .ifLet(\.$destination, action: \.destination)
    }
}
```

이렇게 하면 하나의 parent에서 동시에 여러 presentation이 켜지는 invalid state를 줄일 수 있다.

## Stack-based Navigation

stack-based navigation은 push path를 collection state로 모델링한다.

PopPang에서 stack-based navigation을 쓰는 경우:

- popup detail push
- related popup detail push
- coming popup detail
- coming popup list에서 popup detail로 이어지는 drill-down
- review detail
- alert에서 popup detail 진입
- popup request management detail
- profile setting처럼 탭 root 위로 push되는 화면

### Path 규칙

stack destination은 parent feature 안에 `@Reducer enum Path`로 둔다.

```swift
@Reducer
struct MainTabFeature {
    @Reducer
    enum Path {
        case popupDetail(PopupDetailFeature)
        case reviewDetail(ReviewFeature)
        case profileSetting(ProfileSettingFeature)
    }

    @ObservableState
    struct State {
        var path = StackState<Path.State>()
    }

    enum Action {
        case path(StackActionOf<Path>)
    }

    var body: some ReducerOf<Self> {
        Reduce { state, action in
            switch action {
            case .path:
                return .none
            }
        }
        .forEach(\.path, action: \.path)
    }
}
```

child feature는 `MainTabFeature.Path.State`를 알지 않는다. child에서 `NavigationLink(state:)`를 직접 쓰면 parent의 Path 타입을 알아야 하므로 모듈성이 깨질 수 있다.

권장 흐름:

```swift
case .home(.delegate(.popupSelected(let popup))):
    state.path.append(
        .popupDetail(
            PopupDetailFeature.State(
                userUuid: state.session.userUuid,
                popup: popup,
                isAdmin: state.session.isAdmin
            )
        )
    )
    return .none
```

## App-level Shape

장기 목표는 아래 구조다. 실제 파일과 모듈 분리는 feature migration 속도에 맞춰 점진적으로 진행한다.

```text
PopPang
│
├─ AppFeature
│  │
│  ├─ AuthFlowFeature
│  │  ├─ OnboardingFeature
│  │  ├─ LoginFeature
│  │  └─ SignupFeature
│  │
│  └─ MainTabFeature
│     ├─ HomeFeature
│     │  ├─ PopupListFeature
│     │  ├─ PopupSearchFeature
│     │  └─ PopupDetailFeature
│     │
│     ├─ CalendarFeature
│     │  ├─ CalendarPopupListFeature
│     │  └─ PopupDetailFeature
│     │
│     ├─ MapFeature
│     │  ├─ NearbyPopupListFeature
│     │  └─ PopupDetailFeature
│     │
│     ├─ FavoriteFeature
│     │  ├─ FavoritePopupListFeature
│     │  └─ PopupDetailFeature
│     │
│     └─ ProfileFeature
│        ├─ NoticeFeature
│        ├─ SettingFeature
│        └─ AccountFeature
│
├─ SharedFeature
│  ├─ PopupDetailFeature
│  ├─ PopupCardFeature
│  ├─ PopupImageFeature
│  ├─ PopupLikeFeature
│  ├─ PopupShareFeature
│  ├─ EmptyStateFeature
│  ├─ WebViewFeature
│  └─ PermissionGuideFeature
│
└─ Shared
   ├─ Models
   ├─ Clients
   └─ Caches
```

## Module Boundary

## Session Injection Strategy

세션 source of truth는 항상 `AppFeature.session`이다. 하위 feature는 필요 시 parent가 explicit shared state로 내려준 `session`을 읽는다.

### 1. TCA-ready feature는 state projection + direct scope

`HomeFeature`가 현재 기준선이다.

```swift
@ObservableState
struct AppFeature.State: Equatable {
    var session = SessionState()
    var mainTabCore: MainTabFeature.CoreState?
}
```

```swift
init(session: Shared<UserSession>) {
    self.home = .init(session: session)
}
```

```swift
HomeFeatureView(store: store.scope(state: \.core.home, action: \.home))
```

이 방식에서는 view가 `userUuid`, `nickname`, `isAdmin` 같은 session-derived primitive를 따로 받지 않는다. feature state는 shared `session`을 통해 최신 값을 읽고, reducer는 feature-scoped dependency를 직접 사용한다.

```swift
@Reducer
public struct HomeFeature {
    @Dependencies.Dependency(\.homePopupClient) private var popupClient: HomePopupClient
}
```

### 2. legacy feature는 bridge reducer + view init 주입

아직 내부 state/effect/navigation을 TCA reducer로 옮기지 않은 탭은 `MainTabFeature` 아래에 bridge reducer를 둔다. bridge reducer는 session-derived primitive만 만들고 실제 레거시 화면으로 전달한다.

```swift
var profile: ProfileLegacyBridgeFeature.State {
    get { .init(sessionContext: sessionContext) }
    set {}
}
```

```swift
private struct ProfileLegacyBridgeView: View {
    let store: StoreOf<ProfileLegacyBridgeFeature>

    var body: some View {
        ProfileFeatureView(
            userUuid: store.userUuid,
            nickname: store.nickname,
            isAlerted: store.isAlerted,
            onShowAlert: { _ in
                store.send(.alertTapped)
            }
        )
    }
}
```

이 단계에서는 legacy feature 내부의 기존 `Compound`와 기존 `@Dependency`/`DIContainer` 구조를 유지한다. 즉 `SessionClient`를 억지로 레거시 feature마다 넣지 않고, root session만 parent가 projection해서 bridge에서 넘긴다.

### 3. 점진 마이그레이션의 완료 기준

각 탭이 아래 조건을 만족하면 bridge를 제거하고 direct scope로 옮긴다.

- 탭 root가 public TCA reducer/state/view entry를 가진다.
- 화면 전환 intent를 delegate action으로 올린다.
- 내부 비동기 작업을 feature-scoped TCA dependency로 처리한다.
- parent가 필요한 session-derived 값만 state projection으로 내려줄 수 있다.

### Feature

Feature는 화면 상태와 액션을 가진다.

- `State`: 화면 상태, child state, presentation state
- `Action`: 사용자 입력, lifecycle, response, child action, delegate, navigation action
- `Reducer`: 상태 변경, effect, child reducer composition
- `View`: store action 전송과 store scoping

### SharedFeature

여러 화면에서 재사용되는 화면 또는 독립 UI feature다.

예:

- popup detail
- popup card
- popup image
- popup like
- popup share
- empty state
- web view
- permission guide

현재 `PopupDetailFeature`처럼 이미 독립 feature target으로 존재하는 모듈은 즉시 이동하지 않는다. 먼저 navigation ownership을 TCA로 옮긴 뒤, 중복과 의존성 방향이 분명해질 때 SharedFeature 분리를 진행한다.

### Shared.Models

공통 모델이다.

예:

- User
- UserSession
- Popup
- PopupDetail
- PopupImage
- PopupCategory
- AppError

현재는 `Projects/Domain/Sources/Entities`가 이 역할을 상당 부분 담당한다. 즉시 파일 이동을 하지 않고, Domain 계약 안정화 후 별도 계획으로 분리한다.

### Shared.Clients

API, SDK, 위치, 딥링크 같은 작업 도구를 TCA dependency로 감싸는 계층이다.

예:

- AuthClient
- UserClient
- PopupClient
- FavoriteClient
- SearchClient
- NotificationClient
- LocationClient
- DeepLinkClient

현재는 `DIContainer.shared.resolve(...)`와 `@Dependency` bridge가 섞여 있다. 새 TCA feature는 feature-scoped client를 만들고, 내부에서 기존 usecase protocol을 감싼다. 이때 TCA client의 `liveValue` 안에서 `DIContainer.shared.resolve(...)`를 직접 호출하지 않고, `AppBootstrap` 같은 composition root에서 concrete client를 조립해 `withDependencies`로 주입한다.

### Shared.Caches

쿠키식 전역 저장소 dependency다.

예:

- UserSessionDependency
- AuthTokenDependency
- OnboardingDependency
- FavoritePopupDependency
- RecentSearchDependency
- NotificationTokenDependency
- AppSettingDependency

UserDefaults, Keychain, in-memory cache, notification token sync는 reducer가 직접 접근하지 않고 dependency를 통해 접근한다.

## Reducer Ordering

`switch action` case 순서는 아래 순서를 따른다.

1. binding
2. lifecycle/task
3. 일반 상태 변경 action
4. async response action
5. child action
6. child delegate action
7. stack navigation action
8. tree destination action
9. dismiss action

예:

```swift
switch action {
case .binding:
    return .none

case .task:
    return .run { send in ... }

case .tabSelected(let tab):
    state.selectedTab = tab
    return .none

case .popupResponse(.success(let popups)):
    state.popups = popups
    return .none

case .home(.delegate(.popupSelected(let popup))):
    state.path.append(.popupDetail(.init(popup: popup)))
    return .none

case .path(.element(let id, let action)):
    return reducePathAction(id: id, action: action, state: &state)

case .destination(.presented(.search(.delegate(.dismiss)))):
    state.destination = nil
    return .none

case .destination:
    return .none
}
```

## Migration Order

### 1. App navigation 기준선

- `AppFeature` 도입
- `RootCoordinator` 제거 완료
- `MainTab`, `UserSession` 성격 타입을 Coordinator 밖으로 이동
- App target에서 Coordinator dependency 제거

### 2. MainTab navigation 정리

- `MainTabFeature.Path`로 push destination 통합
- `MainTabFeature.Destination`으로 sheet/fullScreen/search 통합
- `@Presents`는 단일 destination enum state로 사용
- tab root는 중첩 `NavigationStack`을 만들지 않음
- 아직 reducer가 준비되지 않은 탭은 `*LegacyBridgeFeature`로 한시 운영 가능

### 3. Feature escaping routing 제거

- `HomeFeatureView(onSelectPopup:)` 같은 화면 전환 callback 제거
- feature reducer에 delegate action 추가
- parent reducer가 path/destination 변경
- UI component closure는 store action forwarding 용도로만 유지

### 4. Shared dependency 정리

- feature-scoped client 표준화
- 기존 usecase protocol bridge 정리
- Shared.Models/Clients/Caches 분리 여부 검토

### 5. 탭별 점진 전환

- `HomeFeature`: direct scope 완료, search/popupRequest는 feature 내부 tree-based navigation으로 소유
- `HomeFeature`에서 시작하는 연속 push(`coming popup list -> popup detail`)는 `MainTabFeature.path`가 소유
- `popupRequestManagement`처럼 메인 공통 흐름으로 이어지는 push는 `MainTabFeature.path`가 소유
- `Calendar/Map/Favorites/Profile`: bridge reducer를 유지하며 session primitive만 주입
- 각 탭이 TCA reducer entry를 갖추면 `*LegacyBridgeFeature`를 제거하고 direct scope로 전환

## Do Not

- 새 coordinator 타입을 만들지 않는다.
- 새 화면 전환용 escaping closure를 추가하지 않는다.
- route/path/destination state에 `Binding`, `View`, heavy closure를 넣지 않는다.
- child feature가 parent `Path.State`를 직접 import하게 만들지 않는다.
- API, DTO, Domain public protocol을 navigation migration과 함께 무리하게 바꾸지 않는다.
- `NaverMapCoordinator` 같은 SDK bridge를 화면 전환 coordinator와 같은 범주로 취급하지 않는다.

## References

- Tree-based navigation: https://swiftpackageindex.com/pointfreeco/swift-composable-architecture/main/documentation/composablearchitecture/treebasednavigation
- Stack-based navigation: https://swiftpackageindex.com/pointfreeco/swift-composable-architecture/main/documentation/composablearchitecture/stackbasednavigation
