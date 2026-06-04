# Coordinator Guide

## 현재 기준

이 모듈의 coordinator는 V0 컨셉을 따른다.

- coordinator가 `paths / sheet / overlay / fullScreen / bottomSheet` 같은 presentation 상태를 직접 소유한다.
- SwiftUI view는 상태를 직접 바꾸지 않고 intent callback을 coordinator로 올린다.
- route는 가벼운 값만 담는다.
- route 안에 `Binding`, `View`, 무거운 closure를 넣지 않는다.
- container는 상태를 소유하지 않고 SwiftUI presentation 바인딩만 담당한다.

## 흐름 소유권

### RootCoordinator

앱 루트 상태를 소유한다.

- launch
- onboarding
- auth
- register
- main
- logout 후 root 전환

### MainTabCoordinator

메인 탭 안의 전역 navigation을 소유한다.

- `paths: [MainTabRoute]`
- `fullScreen: MainTabFullScreenRoute?`
- tab selection
- main session
- 탭 간 공통 목적지

예:

- popup detail
- coming popup detail
- review detail
- alert
- popup report
- profile setting
- notification
- service terms
- home search fullScreen

MainTab 화면은 하나의 `NavigationStack(path:)`만 가진다. 각 탭 root를 다시 `CoordinatorContainer`로 감싸지 않는다.

### Feature Coordinator

feature coordinator는 feature root를 조립하고, feature에서 올라온 intent를 상위 coordinator로 전달한다.

현재 MainTab 아래에서 feature coordinator는 대부분 root factory와 navigation adapter 역할을 한다. 상위 handler가 없을 때만 독립 실행이나 demo를 위해 자기 local path로 fallback할 수 있다.

예:

- `HomeCoordinator.onSelectPopup`
- `HomeCoordinator.onSearch`
- `HomeCoordinator.onShowComingPopups`
- `ProfileCoordinator.onProfileSetting`
- `ProfileCoordinator.onNotification`
- `ProfileCoordinator.onServiceTerms`

## NavigationStack 규칙

- main flow에서는 `MainTabCoordinatorView`가 단일 `NavigationStack(path: $coordinator.paths)`를 가진다.
- 탭 root view는 중첩 `NavigationStack`을 만들지 않는다.
- onboarding처럼 main flow와 분리된 독립 흐름은 `CoordinatorContainer`를 쓸 수 있다.
- fullScreen 안에서 닫히는 독립 화면은 자체 stack을 가질 수 있다.

## Bottom Sheet 규칙

맵 bottom sheet는 `MapFeatureView`와 `MapFeatureCompound`가 소유한다.

이유:

- sheet position, selected popup, region/sort/detail sheet type이 모두 맵 화면 내부 상태다.
- coordinator에 올리면 route가 화면 로컬 상태를 과하게 알게 된다.
- V0와 동일하게 실제 bottom sheet 동작은 `BottomSheet` 라이브러리 기반으로 유지한다.

따라서 `MapCoordinator`에는 임시 `safeAreaInset` bottom sheet host를 두지 않는다.

전역 bottom sheet가 필요할 때만 coordinator bottomSheet route를 사용한다.

## Route 규칙

좋은 route:

```swift
case popupDetail(userUuid: String, popup: Popup)
case search(userUuid: String)
case profileSetting(userUuid: String, nickname: String, isAlerted: Bool)
```

피해야 하는 route:

```swift
case regionSheet(
    selectedRegion: Binding<RegionList?>,
    onDismiss: () -> Void,
    content: AnyView
)
```

원칙:

- route는 navigation intent다.
- 화면 runtime state는 feature state나 coordinator state에 둔다.
- `Binding`, `View`, closure container는 route에 넣지 않는다.

## 새 흐름 추가 체크리스트

1. 앱 루트 전환인지, MainTab 전역 이동인지, feature 로컬 상태인지 먼저 정한다.
2. MainTab 전역 이동이면 `MainTabRoute` 또는 `MainTabFullScreenRoute`에 case를 추가한다.
3. feature root에는 callback을 추가하고, feature coordinator가 상위 handler로 전달한다.
4. `MainTabCoordinator`에서 handler를 연결한다.
5. `MainTabCoordinatorView`에서 route를 실제 view로 변환한다.
6. feature 안에서만 닫히는 UI state는 feature state에 둔다.

## 현재 구조 요약

```text
RootCoordinator
 -> MainTabCoordinator
    -> HomeCoordinator
    -> CalendarCoordinator
    -> MapCoordinator
    -> FavoritesCoordinator
    -> ProfileCoordinator
```

`MainTabCoordinator`가 메인 flow의 V0 MainCoordinator 역할을 맡는다. feature coordinator는 root 조립과 intent 전달을 맡는다.
