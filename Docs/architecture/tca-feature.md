# PopPang TCA Feature 작성 규칙

이 문서는 PopPang에서 TCA reducer와 SwiftUI view를 작성하는 기준이다. 현재 코드에서 가장 많이 쓰는 관례를 기준으로 삼고, 섞여 있는 부분은 새 코드에서 따를 쪽을 적었다. 화면 전환은 [TCA Navigation](tca-navigation.md), client와 주입은 [의존성 주입](dependency-injection.md)을 본다.

TCA 버전은 `1.25.0`이다(`Tuist/Package.swift`).

## 목차

- [파일 구성](#파일-구성)
- [Reducer 골격](#reducer-골격)
- [State](#state)
- [Action](#action)
- [switch action 순서](#switch-action-순서)
- [Effect](#effect)
- [body 구성](#body-구성)
- [View](#view)
- [새 feature 예시](#새-feature-예시)
- [체크리스트](#체크리스트)

## 파일 구성

```text
Projects/Features/<Name>Feature/
├── Sources/
│   ├── Dependency/<Name>FeatureClient.swift
│   └── Presentation/
│       ├── <Name>Feature.swift        reducer
│       ├── <Name>FeatureView.swift    SwiftUI view
│       └── UI/                        화면 전용 하위 view (필요할 때)
├── Demo/Sources/<Name>FeatureDemoApp.swift
└── Tests/<Name>FeatureTests.swift
```

한 모듈에 화면이 여러 개면 `Presentation/<Screen>/` 아래에 나눈다(`HomeFeatureV2/Sources/Presentation/Home`, `.../Coming`).

## Reducer 골격

```swift
@Reducer
public struct CalendarFeature {
    @ObservableState
    public struct State: Equatable { ... }

    public enum Action { ...; case delegate(Delegate) }

    @Dependency(\.calendarFeatureClient) private var calendarFeatureClient: CalendarFeatureClient

    public init() {}

    public var body: some ReducerOf<Self> { ... }
}

private extension CalendarFeature {
    // effect helper
}
```

- 선언 순서는 `State` → `Action` → `@Dependency` → `init` → `body`다. 일부 파일은 `@Dependency`를 맨 위에 두지만, 새 코드는 이 순서를 따른다.
- 다른 모듈에서 쓰는 reducer, `State`, `Action`, `Delegate`, `init`, `body`는 `public`이다. App 타깃 안의 reducer(`AppFeature`)는 internal이다.
- 긴 effect와 helper는 파일 끝 `private extension <Name>Feature`에 둔다.

## State

- `@ObservableState public struct State: Equatable`로 선언한다. presentation이나 stack에 올라가는 State는 `Identifiable`도 채택한다.
- `Equatable`은 컴파일러가 합성하게 둔다. `Path.State`나 `Destination.State`처럼 합성되지 않는 멤버가 있을 때만 `==`를 직접 쓴다. ([TCA Navigation](tca-navigation.md#equatable-처리))
- parent가 만들거나 고치는 프로퍼티만 `public`으로 열고 나머지는 internal로 둔다. 예: `HomeFeature.State`의 `userUuid`, `nickname`은 `MainTabFeature`가 쓰므로 `public`이다. 현재 코드는 feature마다 섞여 있다.
- 사용자 값은 shared session 대신 `userUuid`, `nickname`, `isAdmin` 같은 값으로 받는다. `init(user: User)`나 `init(userUuid: String)`로 만든다.

reducer에 둘 상태와 view에 둘 상태:

| reducer State | view `@State` |
| --- | --- |
| 서버 데이터, 로딩·오류, 선택한 필터 | sheet를 띄울지 정하는 route(`sheetRoute`), segmented 선택 |
| effect 실행 시점에 영향을 주는 값 | scroll offset, `ListProxy`, 일회성 animation |
| 테스트로 검증해야 하는 값 | 광고 slot store처럼 화면 전용 객체 |

## Action

`Action`은 평평한 enum이고, 중첩은 `case delegate(Delegate)` 하나만 둔다. `BindableAction`, `ViewAction`, `enum View`는 쓰지 않는다.

```swift
// CalendarFeature
public enum Action {
    case onAppear
    case dateSelected(Date)
    case regionSelected(RegionList)
    case toggleLike(Popup)
    case popupSelected(Popup)
    case alertTapped
    case popupDataLoaded(CalendarPopupLoadResult)
    case filteredPopupListLoaded([Popup])
    case loadingChanged(Bool)
    case errorMessageChanged(String?)
    case delegate(Delegate)

    public enum Delegate: Equatable {
        case alertRequested
        case popupSelected(Popup)
    }
}
```

이름 규칙:

| 종류 | 형식 | 예 |
| --- | --- | --- |
| 화면 진입 | `onAppear` | `.onAppear { store.send(.onAppear) }` |
| 사용자 탭 | `<대상>Tapped` | `kakaoLoginTapped`, `alertTapped` |
| 항목 선택 | `<대상>Selected` | `popupSelected(Popup)`, `regionSelected(RegionList)` |
| 입력·값 변경 | `<대상>Changed` | `searchTextChanged(String)` |
| 내부 상태 setter | `loadingChanged(Bool)`, `errorMessageChanged(String?)` | |
| 비동기 결과 (Result) | `<작업>Response(Result<T, Error>)` | `AlertFeature`, `SearchFeature` |
| 비동기 결과 (값) | `<대상>Loaded(T)` | `popupSectionsLoaded(HomePopupSections)` |
| delegate | 요청은 `<대상>Requested`, 끝난 일은 과거형, 닫기는 `dismiss`·`pop`·`close` | `alertRequested`, `authenticated(User)`, `completed(User)`, `dismiss` |

- `Action`은 가능하면 `Equatable`로 만든다. `Result<_, Error>`를 담으면 `Equatable`이 될 수 없으므로 테스트에서 case key path로 받는다.
- 사용자 동작을 parent에 알려야 하면 동작 action에서 delegate를 보낸다.

```swift
case .alertTapped:
    return .send(.delegate(.alertRequested))
```

## 비동기 결과 처리

현재 두 방식이 함께 쓰인다. 기존 feature를 고칠 때는 그 feature의 방식을 따르고, 새 feature는 하나를 골라 일관되게 쓴다.

| 방식 | 흐름 | 쓰는 feature |
| --- | --- | --- |
| Result 응답 | effect가 `send(.xxxResponse(.success(value)))` 또는 `.failure(error)`를 보내고, reducer가 두 case로 처리한다. | Alert, Auth, RegisterFlow, Profile, Search |
| 값 + setter | effect가 `send(.xxxLoaded(value))`, 실패하면 `send(.errorMessageChanged(error.localizedDescription))`, 마지막에 `send(.loadingChanged(false))`를 보낸다. | Home, Calendar, Favorites, Map, PopupDetail |

## switch action 순서

`switch action`은 모든 case를 나열하고 최상위 `default`를 쓰지 않는다. 새 action을 추가했을 때 빠진 처리를 컴파일러가 알려 주게 하기 위해서다.

1. lifecycle: `onAppear`
2. 사용자 입력과 일반 상태 변경
3. 비동기 응답과 내부 setter
4. child action과 child delegate
5. navigation: `path`, `destination`, dismiss·teardown
6. 자기 `delegate`: `return .none`

```swift
case .home(.delegate(.popupSelected(let popup))):
    appendPopupDetail(popup, state: &state)
    return .none

case .home,
        .calendar,
        .map:
    return .none

case .path(.element(let id, let action)):
    return reducePathAction(id: id, action: action, state: &state)

case .destination:
    return .none

case .delegate:
    return .none
```

- 처리하지 않는 child action은 case로 나열해 `return .none`한다.
- 값 바인딩은 `case .x(let value)`를 쓰고, 값이 여러 개면 `case let .x(a, b, c)`를 쓴다.
- 중첩 helper의 `switch`(예: `reducePathAction`)에서는 `default: return .none`을 써도 된다.

## Effect

```swift
// CalendarFeature (일부 생략)
private extension CalendarFeature {
    func loadAllPopupData(state: State) -> Effect<Action> {
        let calendarFeatureClient = calendarFeatureClient

        return .run { [state, calendarFeatureClient] send in
            do {
                let regions = try await calendarFeatureClient.getRegionList()
                let popups = try await calendarFeatureClient.getPersonalFilteredPopupList(
                    state.userUuid,
                    state.selectedRegion?.region ?? "전체",
                    state.selectedDistrict ?? "전체",
                    state.selectedOption.rawValue
                )
                await send(.popupDataLoaded(.init(regions: regions, ..., popups: popups)))
            } catch {
                await send(.errorMessageChanged(error.localizedDescription))
            }

            await send(.loadingChanged(false))
        }
    }
}
```

- 짧은 effect는 reducer 안에 두고, 길면 `private extension`의 helper로 뺀다.
- client는 effect 밖에서 지역 상수로 꺼내 캡처한다. `.run` 클로저가 reducer 전체를 캡처하지 않게 하기 위해서다.
- effect 안에서는 `state`를 바꿀 수 없다. 결과를 action으로 보내고 reducer에서 state를 바꾼다.
- 동시에 여러 요청을 보내면 `async let`을 쓴다(`HomeFeature.loadAllPopupData`).
- 취소가 필요하면 reducer 안에 `private enum CancelID { case search }`를 두고 `.cancellable(id: CancelID.search, cancelInFlight: true)`, `.cancel(id:)`를 쓴다. debounce는 `@Dependency(\.continuousClock)`의 `clock.sleep(for:)`로 만들고 `catch is CancellationError {}`로 취소를 무시한다(`SearchFeature`).
- 로그는 `print` 대신 `Core`의 `Logger.d(_:)`, `Logger.w(_:)`, `Logger.e(_:)`를 쓴다. reducer에 남은 `print`는 정리 대상이다.
- view tree 해제를 기다려야 하면 `await Task.yield()` 뒤 후속 action을 보낸다. ([TCA Navigation](tca-navigation.md#해제-순서가-필요한-전환))

## body 구성

```swift
public var body: some ReducerOf<Self> {
    Scope(state: \.filter, action: \.filter) {
        HomeFilterFeature()
    }

    EmptyReducer()
        .ifLet(\.registerFlow, action: \.registerFlow) {
            RegisterFlowFeature()
        }

    Reduce { state, action in
        switch action { ... }
    }
    .forEach(\.core.path, action: \.path)
    .ifLet(\.core.$destination, action: \.destination)
}
```

- 순서는 `Scope` → optional child의 `EmptyReducer().ifLet` → `Reduce` → `Reduce`에 붙인 `.forEach`·`.ifLet`이다.
- child reducer가 parent보다 먼저 action을 처리해야 하는 경우(로그아웃 중 child 정리 등)가 있으므로 `Scope`와 `ifLet`의 위치를 바꾸지 않는다.
- `BindingReducer`는 쓰지 않는다.

## View

```swift
// CalendarFeatureView (일부 생략)
public struct CalendarFeatureView: View {
    private enum SheetRoute: String, Identifiable {
        case region
        case sort

        var id: String { rawValue }
    }

    let store: StoreOf<CalendarFeature>
    @State private var sheetRoute: SheetRoute?

    public init(store: StoreOf<CalendarFeature>) {
        self.store = store
    }

    public var body: some View {
        VStack(spacing: 0) { ... }
            .onAppear {
                store.send(.onAppear)
            }
    }
}

private extension CalendarFeatureView {
    var selectedRegionBinding: Binding<RegionList?> {
        Binding(
            get: { store.selectedRegion },
            set: { region in
                guard let region else { return }
                store.send(.regionSelected(region))
            }
        )
    }
}
```

- `public struct <Name>FeatureView: View`와 `public init(store:)`를 둔다.
- store는 `let store: StoreOf<Feature>`로 받는다. `$store.scope(...)` binding이 필요할 때(`NavigationStack(path:)`, `.fullScreenCover(item:)`)만 `@Bindable var store`를 쓴다.
- 이벤트는 closure 안에서 `store.send(...)`로 보낸다. binding은 `Binding(get:set:)` 계산 프로퍼티로 만들고 set에서 action을 보낸다.
- 화면 전용 presentation 상태(`sheetRoute`)는 view의 `@State`에 둔다.
- 하위 view는 파일 아래쪽 `private struct <Name>View: View`로 나눈다. 하위 view는 store 대신 값과 `onXxx` UI 이벤트 closure를 받는다.
- iOS 17 이상이라 `WithPerceptionTracking`과 `ViewStore`는 쓰지 않는다.
- 화면 확인은 `#Preview`보다 Demo 앱 타깃을 쓴다.
- view initializer에 화면 전환용 closure를 추가하지 않는다. ([TCA Navigation](tca-navigation.md#closure-구분))
- 목록은 [PopPangListKit](poppang-listkit.md)을 따른다.

## 새 feature 예시

아래 `NoticeFeature`와 `Notice`는 구조를 보여 주기 위한 가상 예시다.

```swift
import ComposableArchitecture
import Domain
import Foundation

@Reducer
public struct NoticeFeature {
    @ObservableState
    public struct State: Equatable {
        public var userUuid: String
        var notices: [Notice] = []
        var isLoading = false
        var errorMessage: String?

        public init(userUuid: String) {
            self.userUuid = userUuid
        }
    }

    public enum Action: Equatable {
        case onAppear
        case noticeSelected(Notice)
        case noticesLoaded([Notice])
        case loadingChanged(Bool)
        case errorMessageChanged(String?)
        case delegate(Delegate)

        public enum Delegate: Equatable {
            case noticeDetailRequested(Notice)
        }
    }

    @Dependency(\.noticeFeatureClient) private var noticeFeatureClient: NoticeFeatureClient

    public init() {}

    public var body: some ReducerOf<Self> {
        Reduce { state, action in
            switch action {
            case .onAppear:
                state.isLoading = true
                state.errorMessage = nil
                return loadNotices(userUuid: state.userUuid)

            case .noticeSelected(let notice):
                return .send(.delegate(.noticeDetailRequested(notice)))

            case .noticesLoaded(let notices):
                state.notices = notices
                return .none

            case .loadingChanged(let isLoading):
                state.isLoading = isLoading
                return .none

            case .errorMessageChanged(let errorMessage):
                state.errorMessage = errorMessage
                return .none

            case .delegate:
                return .none
            }
        }
    }
}

private extension NoticeFeature {
    func loadNotices(userUuid: String) -> Effect<Action> {
        let noticeFeatureClient = noticeFeatureClient
        return .run { send in
            do {
                let notices = try await noticeFeatureClient.getNoticeList(userUuid)
                await send(.noticesLoaded(notices))
            } catch {
                await send(.errorMessageChanged(error.localizedDescription))
            }
            await send(.loadingChanged(false))
        }
    }
}
```

## 체크리스트

- [ ] reducer는 `State` → `Action` → `@Dependency` → `init` → `body` 순서다.
- [ ] `State`는 `Equatable`이고, parent가 쓰는 프로퍼티만 `public`이다.
- [ ] action 이름이 위 규칙을 따르고, parent에 알릴 일은 `delegate`로 보낸다.
- [ ] `switch action`에 최상위 `default`가 없고, 순서 규칙을 따른다.
- [ ] effect는 client를 지역 상수로 꺼내 캡처하고, 결과를 action으로 보낸다.
- [ ] 의존성은 `@Dependency`로만 받는다. ([의존성 주입](dependency-injection.md))
- [ ] view는 `store.send`로만 이벤트를 보내고 화면 전환 closure를 받지 않는다.
- [ ] `TestStore` 테스트를 추가하거나 갱신했다. ([테스트](../development/testing.md))

## 관련 문서

- [TCA Navigation](tca-navigation.md)
- [의존성 주입](dependency-injection.md)
- [PopPangListKit](poppang-listkit.md)
- [Swift 스타일](../development/swiftstyle.md)
