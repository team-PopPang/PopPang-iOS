# PopPang TCA Navigation

이 문서는 PopPang에서 화면 전환을 TCA state와 action으로 모델링하는 기준이다. 화면을 추가하거나 이동 경로를 바꾸기 전에 읽는다.

코드와 이 문서가 다르면 현재 코드를 기준으로 판단하고, 같은 작업에서 이 문서를 고친다.

## 목차

- [결정 사항](#결정-사항)
- [Navigation 소유권 지도](#navigation-소유권-지도)
- [Tree-based와 Stack-based 선택 기준](#tree-based와-stack-based-선택-기준)
- [Tree-based Navigation](#tree-based-navigation)
- [Stack-based Navigation](#stack-based-navigation)
- [Child에서 Parent로 의도를 올리는 흐름](#child에서-parent로-의도를-올리는-흐름)
- [DestinationFeature 래퍼](#destinationfeature-래퍼)
- [View 연결 규칙](#view-연결-규칙)
- [세션 동기화](#세션-동기화)
- [해제 순서가 필요한 전환](#해제-순서가-필요한-전환)
- [Closure 구분](#closure-구분)
- [Equatable 처리](#equatable-처리)
- [하지 않는 것](#하지-않는-것)
- [새 화면 전환 체크리스트](#새-화면-전환-체크리스트)

## 결정 사항

- 화면 전환은 parent reducer의 `StackState` 또는 `@Presents` destination 변경으로만 일어난다.
- child feature는 다른 feature를 직접 조립하지 않는다. `.delegate(...)` action으로 의도만 올린다.
- 화면 전환을 위한 `@escaping` closure를 새로 추가하지 않는다.
- 전역 세션의 source of truth는 `AppFeature.State.session`(`@Shared var session: UserSession`)이다.

## Navigation 소유권 지도

| 소유자 | 위치 | 소유하는 전환 | 방식 |
| --- | --- | --- | --- |
| `AppFeature` | `Projects/App/Sources/AppCore/Navigation/8. AppFeature.swift` | launch → onboarding → auth → register → main 루트 전환 | `AppRootDestination` enum과 optional child state(`registerFlow`, `mainTab`) |
| `AppFeature` | 같은 파일 | 온보딩에서 로그인으로 push | `StackState<OnboardingPath.State>` |
| `MainTabFeature` | `Projects/Features/MainTabFeature/Sources/MainTabFeature.swift` | 탭 선택, 여러 탭에서 공통으로 쓰는 push | `StackState<Path.State>` |
| `MainTabFeature` | 같은 파일 | 검색, RN 팝업 제보 fullScreen | `@Presents var destination: Destination.State?` |
| `SearchDestinationFeature` | 같은 파일 | 검색 fullScreen 안의 팝업 상세·리뷰 push | 자체 `StackState<Path.State>` |
| 각 tab feature | `Projects/Features/<Name>Feature/Sources/**` | 탭 내부 필터 sheet, 선택 상태처럼 화면 로컬 상태 | feature state 또는 view local state |

`MainTabFeature`의 현재 `Path`와 `Destination`은 아래와 같다. 케이스를 추가하거나 지우면 이 표도 고친다.

| 종류 | case | child reducer |
| --- | --- | --- |
| `Path` | `popupRequestManagement` | `PopPangRNFeature` |
| `Path` | `homeComingPopupDetail` | `HomeComingPopupDetailDestinationFeature` (`HomeFeatureV2`) |
| `Path` | `popupDetail` | `PopupDetailDestinationFeature` |
| `Path` | `reviewDetail` | `ReviewFeature` |
| `Path` | `alert` | `AlertFeature` |
| `Path` | `profileSetting` | `ProfileSettingFeature` |
| `Path` | `notifications` | `NotificationDestinationFeature` |
| `Path` | `serviceTerms` | `ServiceTermsDestinationFeature` |
| `Destination` | `search` | `SearchDestinationFeature` |
| `Destination` | `popupRequest` | `PopPangRNFeature` |

## Tree-based와 Stack-based 선택 기준

| 질문 | 예 | 선택 |
| --- | --- | --- |
| 동시에 하나만 떠 있어야 하나요? | 앱 루트, auth 단계, sheet, fullScreenCover, alert, confirmationDialog | tree-based |
| 같은 종류의 화면이 계속 쌓일 수 있나요? | 팝업 상세 → 관련 팝업 상세 → 리뷰 | stack-based |
| 여러 탭에서 같은 화면으로 이동하나요? | 팝업 상세, 알림, 프로필 설정 | `MainTabFeature.Path` |
| 한 화면 안에서만 의미가 있는 상태인가요? | 지역·정렬 sheet, segmented 선택, BottomSheet 높이 | feature state 또는 view local state |

## Tree-based Navigation

여러 presentation이 가능하면 optional을 여러 개 두지 않는다. `@Reducer enum Destination`을 만들고 State에는 `@Presents var destination` 하나만 둔다. 동시에 두 화면이 떠 있는 잘못된 상태를 타입으로 막기 위해서다.

```swift
// Avoid
@ObservableState
struct State {
    @Presents var search: SearchFeature.State?
    @Presents var popupRequest: PopPangRNFeature.State?
}

// Preferred: MainTabFeature
@Reducer
public enum Destination {
    case search(SearchDestinationFeature)
    case popupRequest(PopPangRNFeature)
}

@ObservableState
public struct CoreState: Equatable {
    @Presents var destination: Destination.State?
}
```

reducer는 `.ifLet(\.core.$destination, action: \.destination)`로 연결한다. 닫을 때는 child가 `.delegate(.dismiss)`를 보내고 parent가 `destination = nil`로 바꾼다.

앱 루트 전환은 예외적으로 `AppRootDestination` enum과 optional child state를 함께 쓴다. 루트는 presentation이 아니라 화면 전체 교체이고, `registerFlow`와 `mainTab`처럼 진입할 때 만들고 나갈 때 해제해야 하는 상태를 따로 관리하기 때문이다.

## Stack-based Navigation

stack destination은 parent 안의 `@Reducer enum Path`로 정의하고, parent State가 `StackState<Path.State>`를 소유한다.

```swift
@Reducer
public enum Path {
    case popupDetail(PopupDetailDestinationFeature)
    case reviewDetail(ReviewFeature)
}

var path = StackState<Path.State>()

// body
Reduce { state, action in ... }
    .forEach(\.core.path, action: \.path)
```

- child feature는 parent의 `Path.State`를 알지 않는다. child 화면에서 `NavigationLink(state:)`를 직접 쓰지 않는다.
- path element의 delegate는 `case .path(.element(let id, let action))`에서 `reducePathAction(id:action:state:)` 같은 private helper로 넘겨 처리한다.
- 닫기는 `state.core.path.pop(from: id)`를 쓴다.
- path와 destination state에는 child state와 navigation에 필요한 값만 담는다. `Binding`, `View`, 무거운 closure를 넣지 않는다.

## Child에서 Parent로 의도를 올리는 흐름

```text
View 버튼 탭
→ child action (`popupSelected(popup)`)
→ child reducer가 `.send(.delegate(.popupSelected(popup)))`
→ parent reducer가 `case .home(.delegate(.popupSelected(let popup)))`에서 path에 추가
```

```swift
// child: HomeFeature (HomeFeatureV2)
case .popupSelected(let popup):
    return .send(.delegate(.popupSelected(popup)))

// parent: MainTabFeature
case .home(.delegate(.popupSelected(let popup))):
    appendPopupDetail(popup, state: &state)
    return .none
```

- delegate case 이름은 parent가 할 일이 아니라 child에서 일어난 일로 짓는다. 예: `popupSelected`, `alertTapped`, `dismiss`, `logoutRequested`.
- 여러 탭에서 같은 화면을 열면 `appendPopupDetail(_:state:)`처럼 parent helper 하나로 모은다.
- parent는 child delegate만 처리하고 나머지 child action은 `return .none`으로 둔다.

## DestinationFeature 래퍼

child feature의 공개 API가 parent의 path와 맞지 않으면, parent 모듈에 `<Name>DestinationFeature`를 만들어 child를 감싼다. 래퍼는 child 상태를 `content` 같은 이름으로 `Scope`하고, child의 이벤트를 parent가 처리할 delegate로 바꾼다.

| 래퍼 | 위치 | 하는 일 |
| --- | --- | --- |
| `PopupDetailDestinationFeature` | `MainTabFeature.swift` | `PopupDetailFeature`의 관련 팝업 선택, 리뷰 보기, 비활성화 완료, 좋아요 변경을 delegate로 바꾼다. |
| `SearchDestinationFeature` | `MainTabFeature.swift` | `SearchFeature`를 감싸고 fullScreen 안의 자체 `Path`를 소유한다. |
| `HomeComingPopupDetailDestinationFeature` | `HomeFeatureV2` | 오픈 예정 팝업 목록의 팝업 선택을 delegate로 올린다. |
| `NotificationDestinationFeature`, `ServiceTermsDestinationFeature` | `MainTabFeature.swift` | 아직 TCA reducer가 없는 정적 화면을 path에 올리기 위한 빈 reducer다. |

래퍼는 화면 전환을 결정하지 않는다. 전환은 래퍼의 delegate를 받은 parent가 결정한다.

## View 연결 규칙

- 메인 흐름의 `NavigationStack`은 `MainTabFeatureView`에 하나만 둔다. `TabView`가 그 안에 들어가고, 탭 root view는 `NavigationStack`을 새로 만들지 않는다.
- 탭 root는 `store.scope(state: \.core.home, action: \.home)`처럼 직접 scope해서 만든다.
- `destination:` 클로저에서 `switch store.state`로 path case별 view를 만든다.
- presentation은 case마다 `.fullScreenCover(item: $store.scope(state: \.core.destination?.search, action: \.destination.search))`처럼 연결한다.
- fullScreenCover 안에서 다시 push가 필요하면 그 destination feature가 자체 `NavigationStack`과 `Path`를 갖는다(`SearchDestinationView`).

## 세션 동기화

- `MainTabFeature`는 `@Shared var session`을 root 세션 동기화에만 쓴다. child feature에는 `userUuid`, `nickname`, `isAdmin` 같은 사용자 값만 넘긴다.
- child feature는 shared `session`을 직접 읽지 않는다.
- 사용자 값이 바뀌면 child가 delegate로 알리고, `MainTabFeature`가 `core.user`, 관련 child 상태, `state.$session.withLock { ... }`을 함께 갱신한다. 예: `profileSetting(.delegate(.nicknameUpdated))`에서 `core.home.nickname`과 `core.profile.nickname`을 같이 바꾼다.

## 해제 순서가 필요한 전환

SwiftUI가 view tree를 해제하는 중에 state를 먼저 지우면 lifecycle callback이 사라진 state로 action을 보낼 수 있다. 그래서 아래 전환은 두 단계로 처리한다.

| 전환 | 1단계 | 2단계 |
| --- | --- | --- |
| 로그아웃 | `MainTabFeature`가 `path`와 `destination`을 비우고 `Task.yield()` 뒤 `.delegate(.logout)`을 보낸다. `AppFeature`는 `isLoggingOut = true`로 루트를 바꾸되 `mainTab`은 남긴다. | `MainTabFeatureView.onDisappear` → `mainTabViewDidDisappear` → `Task.yield()` → `logoutTeardownCompleted`에서 `mainTab = nil`로 지운다. |
| 온보딩 이탈 | 루트를 다른 destination으로 바꾼다. | `onboardingRootDidDisappear` → `Task.yield()` → `onboardingTeardownCompleted`에서 온보딩 state와 path를 초기화한다. |
| 검색 닫기 | `search(.delegate(.dismiss))`를 받으면 `Task.yield()`를 기다린다. | `searchDismissTeardownCompleted`에서 destination이 여전히 search일 때만 `nil`로 바꾼다. |

새 전환에서 같은 문제가 보이면 이 패턴을 따르고, 2단계 action에서 `guard`로 상태를 다시 확인한다.

## Closure 구분

| 종류 | 예 | 기준 |
| --- | --- | --- |
| 화면 전환용 escaping closure | `PopupDetailFeatureView`의 `onSelectRelatedPopup`·`onShowReviews`, `ComingPopupDetailFeatureView`의 `onSelectPopup`처럼 다음 화면 이동을 parent에 맡기는 closure | 새로 추가하지 않는다. 남아 있는 closure는 해당 화면을 고칠 때 delegate action으로 바꾼다. |
| UI 이벤트 closure | `GridPopupCell`의 `toggleLike: { store.send(.favoriteToggleTapped(popupUuid: popup.popupUuid)) }`, `HomeNavigationBar`의 `onSearch`·`onAlert` | 허용한다. closure 안에서는 store action만 보낸다. |
| SDK delegate bridge | `NaverMapCoordinator`(MapFeature)의 지도·위치 delegate, `AppNotificationManager`의 알림 callback | 허용한다. 이름에 Coordinator가 있어도 화면 전환을 맡지 않는다. 가능하면 client dependency나 adapter로 감싸 reducer action으로 들어오게 한다. |

`PopupDetailFeatureView`처럼 아직 callback 파라미터가 남은 화면은 parent의 destination view에서 callback을 `store.send(...)`로 바꿔 연결한다. callback을 늘리지 말고, 해당 feature를 고칠 때 delegate action으로 옮긴다.

## Equatable 처리

`@Reducer enum`이 만든 `Path.State`와 `Destination.State`는 자동으로 `Equatable`이 되지 않는다. State가 `Equatable`이어야 하면 아래 중 하나를 쓴다.

- 모든 child state가 `Equatable`이면 `extension AppFeature.OnboardingPath.State: Equatable {}`처럼 conformance를 추가한다.
- 그렇지 않으면 `MainTabFeature.CoreState`처럼 `==`를 직접 구현하고 `destinationsEqual`, `pathsEqual` helper로 case별로 비교한다. path는 `lhs.ids == rhs.ids`를 먼저 비교한다.

## 하지 않는 것

- 화면 전환용 escaping closure를 추가하지 않는다.
- State에 presentation optional을 여러 개 나열하지 않는다.
- child feature가 parent `Path.State`를 import하게 만들지 않는다.
- 탭 root view 안에 `NavigationStack`을 중첩하지 않는다.
- path와 destination state에 `Binding`, `View`, 무거운 closure를 넣지 않는다.
- navigation 작업을 하면서 API, DTO, Domain public protocol을 함께 바꾸지 않는다.

## 새 화면 전환 체크리스트

- [ ] 루트 전환, MainTab 공통 이동, feature 로컬 상태 중 무엇인지 정했다.
- [ ] tree-based인지 stack-based인지 위 선택 기준으로 정했다.
- [ ] child feature에 delegate case를 추가하고, parent에서만 path나 destination을 바꾼다.
- [ ] child API가 맞지 않으면 parent 모듈에 `<Name>DestinationFeature` 래퍼를 둔다.
- [ ] `MainTabFeatureView`의 `destination:` switch나 `.fullScreenCover`를 연결했다.
- [ ] State가 `Equatable`이면 새 case를 비교 코드에 추가했다.
- [ ] 해제 순서 문제가 없는지 확인했다.
- [ ] parent reducer 테스트에서 delegate를 보냈을 때 path나 destination이 바뀌는지 확인했다. 실행 방법은 [테스트](../development/testing.md)를 따른다.
- [ ] 이 문서의 소유권 지도와 `Path`/`Destination` 표를 고쳤다.

## 관련 문서

- [아키텍처](architecture.md)
- [TCA Feature 작성 규칙](tca-feature.md)
- [의존성 주입](dependency-injection.md)
- [TCA Tree-based navigation](https://swiftpackageindex.com/pointfreeco/swift-composable-architecture/main/documentation/composablearchitecture/treebasednavigation)
- [TCA Stack-based navigation](https://swiftpackageindex.com/pointfreeco/swift-composable-architecture/main/documentation/composablearchitecture/stackbasednavigation)
