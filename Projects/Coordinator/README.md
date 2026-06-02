# Coordinator Guide

## 현재 구현 메모

- 현재 `Projects/Coordinator` 구현은 `V0` 스타일에 가깝게 단순화되어 있다.
- `NavigationController`와 `PresentationStore`는 제거되었고, 각 coordinator가 `paths / sheet / overlay / fullScreen / bottomSheet` 상태를 직접 소유한다.
- 공통 바인딩은 `CoordinatorContainer`, `BottomSheetCoordinatorContainer`가 담당한다.
- 아래 본문 중 `NavigationController`, `PresentationStore`, `BottomSheetPresentationStore` 중심 설명은 이전 구조 기준 참고 문서다.

이 문서는 PopPang에서 `Coordinator`를 왜 두는지, `NavigationController`와 무엇이 다른지,  
그리고 `push / sheet / fullScreen / overlay / bottomSheet`를 어디서 관리해야 하는지 정리한 가이드다.

예전 `V0`의 `CoordinatorContainer`는 화면 이동 관련 상태를 한 객체에 모두 올려서 한 번에 바인딩했다.  
그 방식은 시작은 빠르지만, feature가 늘수록 전역 상태가 비대해지고 view 갱신 범위도 커지기 쉬웠다.

현재 구조의 목표는 다음 3가지다.

- 화면 이동 책임을 feature 단위로 나눈다.
- route는 가벼운 값으로 유지한다.
- 실제 화면 표시 상태는 필요한 coordinator 범위에서만 소유한다.

## 한 줄 정의

- `Coordinator`: 어디로 갈지 결정하고, 어떤 화면 흐름을 책임질지 아는 객체
- `NavigationController`: push 스택 상태를 저장하는 객체
- `PresentationStore`: sheet, fullScreen, overlay, bottomSheet 같은 표시 상태를 저장하는 객체
- `CoordinatedView`: coordinator 상태를 SwiftUI에 바인딩하는 공통 컨테이너
- `Feature`: 사용자 액션을 route intent로 올리는 화면 계층

즉:

- `Coordinator`는 흐름 책임자다.
- `NavigationController`는 push 상태 저장소다.
- `PresentationStore`는 모달 상태 저장소다.
- `CoordinatedView`는 바인딩 전용 호스트다.

## 왜 둘을 나누는가

`Coordinator`와 `NavigationController`를 하나로 합치면 처음엔 단순해 보인다.  
하지만 시간이 지나면 "어디로 갈지 판단하는 책임"과 "현재 스택을 저장하는 책임"이 뒤섞인다.

PopPang에서는 이 둘을 분리해서 본다.

- `Coordinator`는 정책을 가진다.
  - 검색으로 가야 하는지
  - 로그아웃 후 auth flow로 보내야 하는지
  - 맵 바텀시트를 띄워야 하는지
- `NavigationController`는 상태만 가진다.
  - 현재 path가 무엇인지
  - push/pop/popToRoot를 어떻게 반영할지

비유하면:

- `Coordinator` = 길 안내하는 사람
- `NavigationController` = 실제 이동 기록을 적는 노트

## 이 저장소에서의 실제 역할

### 1. Coordinator

[Coordinator.swift](/Users/kimdonghyeon/2025/개발/앱출시/PopPang/PopPang/Projects/Coordinator/Sources/Base/Coordinator.swift:4)

이 프로토콜은 각 흐름 단위가 공통으로 가져야 할 것을 정의한다.

- 어떤 `Route`를 쓰는지
- 루트 화면이 무엇인지
- 특정 route를 어떤 화면으로 바꿀지
- 어떤 `navigationController`를 쓸지

즉 coordinator는 "이 흐름을 어떻게 조립하고 연결할지"를 안다.

### 2. NavigationController

[NavigationController.swift](/Users/kimdonghyeon/2025/개발/앱출시/PopPang/PopPang/Projects/Coordinator/Sources/Base/NavigationController.swift:4)

이 타입은 단순하다.

- `navigationPath`
- `push`
- `dismiss`
- `popToRoot`

중요한 점은:

- 이 객체는 `search`가 무슨 화면인지 모른다.
- `popupDetail`이 어떤 feature인지 모른다.
- 그냥 path를 저장하고 바꾸기만 한다.

즉 "상태는 알지만 의미는 모른다."

### 3. CoordinatedView

[CoordinatedView.swift](/Users/kimdonghyeon/2025/개발/앱출시/PopPang/PopPang/Projects/Coordinator/Sources/Base/CoordinatedView.swift:3)

이 뷰는 coordinator의 `navigationController`를 `NavigationStack`에 연결해 주는 얇은 호스트다.

역할은 딱 이것이다.

- coordinator의 루트 뷰를 띄운다.
- navigation path를 바인딩한다.

즉 "코디네이터를 실제 SwiftUI 화면에 붙이는 어댑터"다.

이건 사용자가 공유한 Medium 글의 핵심 패턴과 같다.

- coordinator가 `rootView`와 `coordinate(_:)`를 가진다
- `NavigationController`는 path만 가진다
- 공통 `CoordinatedView`가 `NavigationStack` 바인딩을 담당한다

즉 PopPang도 기본 push 구조는 이미 그 글의 방향을 따른다.

### 4. BottomSheetCoordinatedView

[BottomSheetCoordinatedView.swift](/Users/kimdonghyeon/2025/개발/앱출시/PopPang/PopPang/Projects/Coordinator/Sources/Base/BottomSheetCoordinatedView.swift:1)

맵처럼 바텀시트가 필요한 coordinator는 `BottomSheetCoordinator`를 채택하고,  
공통 `BottomSheetCoordinatedView`가 바텀시트 바인딩을 대신한다.

역할은 다음과 같다.

- coordinator의 `navigationController`를 `NavigationStack`에 바인딩
- coordinator의 `bottomSheetStore`를 읽어 화면 하단에 바인딩
- coordinator가 만든 `bottomSheet(for:)` 뷰를 실제로 붙임

중요한 점:

- container가 route를 판단하지 않는다
- container가 상태를 소유하지 않는다
- coordinator가 상태와 화면 조립 책임을 가진다
- container는 바인딩만 공통화한다

## 계층 구조를 쉽게 보면

현재 구조는 대략 이렇게 읽으면 된다.

```text
RootCoordinator
 -> MainTabCoordinator
   -> HomeCoordinator
   -> MapCoordinator
   -> FavoritesCoordinator
   -> ProfileCoordinator
```

의미는 다음과 같다.

- `RootCoordinator`: 앱 루트 흐름 담당
- `MainTabCoordinator`: 메인 탭 구조 담당
- `HomeCoordinator`: 홈 내부 이동 담당
- `MapCoordinator`: 맵 내부 이동과 맵 로컬 바텀시트 담당

## 실제 흐름 예시

### 예시 1. 홈에서 검색으로 이동

[HomeCoordinator.swift](/Users/kimdonghyeon/2025/개발/앱출시/PopPang/PopPang/Projects/Coordinator/Sources/MainTabCoordinator/HomeCoordinator.swift:11)

흐름은 이렇게 본다.

1. `HomeFeature`가 "검색 버튼 탭"을 감지한다.
2. feature는 navigator에게 `showSearch()`를 보낸다.
3. `HomeCoordinator`가 `SearchCoordinator`를 준비한다.
4. `HomeCoordinator`가 `navigationController.push(.search)`를 호출한다.
5. `NavigationStack`이 path 변화를 보고 화면을 전환한다.

여기서 역할 분리:

- 검색으로 가야 한다고 판단하는 것: `HomeCoordinator`
- 실제 path에 `.search`를 넣는 것: `NavigationController`

### 예시 2. 프로필에서 로그아웃

[ProfileCoordinator.swift](/Users/kimdonghyeon/2025/개발/앱출시/PopPang/PopPang/Projects/Coordinator/Sources/MainTabCoordinator/ProfileCoordinator.swift:4)

로그아웃은 프로필 내부에서 끝나는 일이 아니다.  
앱 루트를 바꾸는 일이다.

그래서:

1. `ProfileFeature` 또는 `ProfileCoordinator`가 로그아웃 intent를 받는다.
2. `ProfileCoordinator`는 부모인 `MainTabCoordinator` 또는 `RootCoordinator` 방향으로 요청을 올린다.
3. 최종적으로 `RootCoordinator`가 auth flow로 전환한다.

즉 로그아웃은 feature local navigation이 아니라 app level navigation이다.

### 예시 3. 맵에서 바텀시트 열기

[MapCoordinator.swift](/Users/kimdonghyeon/2025/개발/앱출시/PopPang/PopPang/Projects/Coordinator/Sources/MainTabCoordinator/MapCoordinator.swift:5)

이건 맵 내부에서만 끝나는 흐름이므로 `MapCoordinator` 책임이다.

1. `MapFeature`가 "목록 바텀시트 열기" intent를 만든다.
2. `MapFeatureRootView`가 navigator의 `showPopupListSheet()`를 호출한다.
3. `MapCoordinator`가 `bottomSheetStore.present(.popupList)`를 호출한다.
4. host view가 store 상태를 읽고 실제 바텀시트를 붙인다.

핵심은:

- feature는 시트를 직접 띄우지 않는다.
- coordinator가 시트 상태를 소유한다.
- route는 가벼운 값만 가진다.

## PopPang에서 책임을 어디에 둘지

### 전역 coordinator가 맡는 것

- 앱 시작
- 온보딩 진입
- 인증 여부에 따른 루트 전환
- 메인 탭 진입
- feature A에서 feature B로 넘어가는 앱 전체 흐름
- deep link 진입
- 전역 sheet / fullScreen / overlay

예:

- 로그아웃 후 auth flow 전환
- 강제 업데이트 시트
- 앱 공지 overlay

### feature coordinator가 맡는 것

- 해당 feature 내부 push
- 해당 feature 내부 sheet
- 해당 feature 내부 fullScreen
- 해당 feature 내부 bottomSheet
- 해당 feature 내부 선택 플로우

예:

- 홈에서 검색 상세 push
- 홈 내부 정렬/필터 시트
- 맵 목록 바텀시트
- 맵 상세 바텀시트

## presentation 상태는 어떻게 본다

현재 기준:

- `push` 상태: `NavigationController`
- `sheet / overlay / fullScreen`: 별도 `PresentationStore`
- `bottomSheet`: `BottomSheetPresentationStore`

즉 "코디네이터가 모든 것을 직접 들고 있는 구조"보다는  
"코디네이터가 필요한 상태 저장소를 소유하는 구조"로 이해하면 된다.

그리고 UI 바인딩은 가능한 한 공통 container로 올린다.

- `push`: `CoordinatedView`
- `bottomSheet`: `BottomSheetCoordinatedView`

이 방향이 Medium 글의 장점과 사용자가 원한 "각 feature마다 host 코드를 다시 쓰지 않는 구조"를 함께 만족시킨다.

## bottomSheet를 왜 feature coordinator 기본으로 두는가

바텀시트는 대체로 특정 화면의 로컬 상호작용과 강하게 붙는다.

예를 들면 맵에서는:

- 어떤 항목이 선택됐는지
- 현재 목록 시트인지 상세 시트인지
- 어느 높이 detent에 있는지

이런 정보가 모두 맵 화면 맥락 안에서 움직인다.

이걸 전역 coordinator가 들기 시작하면:

- 전역 객체가 feature 로컬 state까지 알게 되고
- 화면 경계가 무너지고
- 다시 `V0`처럼 거대한 container로 돌아가기 쉽다

그래서 기본 원칙은:

- 바텀시트가 특정 feature 안에서만 의미가 있으면 `feature coordinator`
- 앱 어디서든 공통으로 떠야 하면 `전역 coordinator`

## route는 무엇을 담고, 무엇을 담지 않는가

좋은 route:

```swift
public enum MapBottomSheetRoute: String, BottomSheetPresentingRoute {
    case popupList
    case popupDetail
}
```

이런 route는 좋다.

- 식별 가능하다
- 가볍다
- 테스트하기 쉽다

나쁜 route 예시:

```swift
case popupDetail(
    selectedPopup: Binding<Popup?>,
    onDismiss: () -> Void,
    content: AnyView
)
```

이건 피한다.

- `Binding`이 들어감
- closure가 들어감
- view 자체가 들어감
- navigation intent가 아니라 runtime UI state가 섞임

원칙:

- route에는 식별자와 경량 값만 둔다
- `Binding`, `View`, 무거운 closure는 넣지 않는다

## 사용 예시

### 1. feature는 intent만 보낸다

```swift
public struct MapFeatureRootView: View {
    private let navigator: (any MapFeatureNavigating)?
    @State private var compound = MapFeatureCompound()

    public var body: some View {
        MapFeatureView(compound: compound)
            .onChange(of: compound.state.route) { _, route in
                guard let route else { return }

                switch route {
                case .popupListSheet:
                    navigator?.showPopupListSheet()
                case .popupDetailSheet:
                    navigator?.showPopupDetailSheet()
                case .dismissBottomSheet:
                    navigator?.dismissBottomSheet()
                }

                compound.send(.routeHandled)
            }
    }
}
```

포인트:

- feature는 직접 `sheet`를 띄우지 않는다
- feature는 "무엇을 하고 싶은지"만 coordinator에 전달한다

### 2. coordinator가 로컬 bottomSheet 상태를 소유한다

```swift
@MainActor
public final class MapCoordinator: BottomSheetCoordinator, MapFeatureNavigating {
    public let navigationController = NavigationController()
    public let bottomSheetStore = BottomSheetPresentationStore<MapBottomSheetRoute>()

    public var rootView: some View {
        MapFeatureRootView(navigator: self)
    }

    public func showPopupListSheet() {
        bottomSheetStore.present(.popupList)
    }

    public func showPopupDetailSheet() {
        bottomSheetStore.present(.popupDetail)
    }

    public func dismissBottomSheet() {
        bottomSheetStore.dismiss()
    }

    public func bottomSheet(for route: MapBottomSheetRoute) -> some View {
        MapBottomSheetHost(route: route)
    }
}
```

포인트:

- 실제 표시 상태는 coordinator가 가진다
- 공통 container가 그 상태를 읽어서 붙인다

### 2-A. 공통 container가 bottomSheet 바인딩을 맡는다

```swift
BottomSheetCoordinatedView(coordinator.mapCoordinator)
```

포인트:

- feature마다 `safeAreaInset`을 직접 붙이지 않는다
- 바인딩 실수를 줄이기 위해 container가 공통으로 담당한다
- coordinator는 상태와 시트 화면만 제공한다

### 3. route는 가벼운 값만 둔다

```swift
public enum MapBottomSheetRoute: String, BottomSheetPresentingRoute {
    case popupList
    case popupDetail

    public var preferredDetent: BottomSheetDetent {
        switch self {
        case .popupList: .fraction(0.4)
        case .popupDetail: .fraction(0.6)
        }
    }
}
```

포인트:

- route는 상태를 설명하는 값이다
- SwiftUI 객체나 클로저 컨테이너가 아니다

## 새 화면 흐름을 추가할 때 체크리스트

### push 화면 추가

1. 어느 coordinator 책임인지 먼저 정한다.
2. route enum case를 추가한다.
3. coordinator가 필요한 하위 coordinator를 생성한다.
4. `navigationController.push(...)`를 호출한다.
5. `coordinate(_:)`에서 route를 실제 화면으로 바꾼다.

### sheet / fullScreen / overlay 추가

1. 이 표시가 앱 전역인지 feature 로컬인지 정한다.
2. 해당 범위 coordinator에 store를 둔다.
3. route는 가벼운 값으로 만든다.
4. host view에서 store를 바인딩한다.

### bottomSheet 추가

1. 기본적으로 feature coordinator에 둔다.
2. `BottomSheetPresentationStore<Route>`를 만든다.
3. feature는 navigator intent만 보낸다.
4. coordinator가 `present`, `dismiss`, `bottomSheet(for:)`를 담당한다.
5. 공통 `BottomSheetCoordinatedView`가 store 상태를 읽어 실제 바텀시트를 붙인다.

## 지금 문서 기준 핵심 결론

- `Coordinator`는 흐름 책임자다.
- `NavigationController`는 push 상태 저장소다.
- 둘은 같은 게 아니다.
- `CoordinatedView`는 공통 바인딩 컨테이너다.
- 전역 흐름은 전역 coordinator가 맡는다.
- feature 안에서 닫히는 흐름은 feature coordinator가 맡는다.
- bottomSheet는 기본적으로 feature coordinator가 가진다.
- feature는 intent만 보내고, presentation 상태는 coordinator가 소유한다.
- 공통 container는 상태를 소유하지 않고 바인딩만 담당한다.
