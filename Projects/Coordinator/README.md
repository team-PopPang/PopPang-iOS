# Coordinator Guide

## 상태

`Projects/Coordinator`는 legacy 모듈이며 제거 대상이다.

새 화면 전환은 이 모듈에 추가하지 않는다. PopPang의 navigation 기준은 `Docs/tca-navigation-guidelines.md`를 따른다.

현재 남아 있는 coordinator 코드는 TCA navigation 전환 전까지 기존 동작을 이해하거나 제거 범위를 파악하기 위한 reference로만 본다.

## 이전 기준

이 모듈의 coordinator는 V0 컨셉을 따른다.

- coordinator가 `paths / sheet / overlay / fullScreen / bottomSheet` 같은 presentation 상태를 직접 소유한다.
- SwiftUI view는 상태를 직접 바꾸지 않고 intent callback을 coordinator로 올린다.
- route는 가벼운 값만 담는다.
- route 안에 `Binding`, `View`, 무거운 closure를 넣지 않는다.
- container는 상태를 소유하지 않고 SwiftUI presentation 바인딩만 담당한다.

이 기준은 더 이상 신규 구현 기준이 아니다. 신규 구현은 TCA reducer state/action으로 navigation을 소유한다.

## 흐름 소유권

### RootCoordinator

앱 루트 상태를 소유하던 legacy 계층이다.

- launch
- onboarding
- auth
- register
- main
- logout 후 root 전환

대체 목표:

- `AppFeature`가 tree-based navigation으로 root destination을 소유한다.
- launch/session/onboarding/auth/main 전환은 `AppFeature.State`와 `AppFeature.Destination`으로 표현한다.

### MainTabCoordinator

메인 탭 안의 전역 navigation을 소유하던 legacy 계층이다. 현재 active main flow는 App 모듈의 `MainTabFeature` TCA shell로 옮기는 중이다.

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
- popup request
- popup request management
- popup request management detail
- profile setting
- notification
- service terms
- home search fullScreen

MainTab 화면은 하나의 `NavigationStack(path:)`만 가진다. 각 탭 root를 다시 `CoordinatorContainer`로 감싸지 않는다.

대체 목표:

- push 흐름은 `MainTabFeature.Path`와 `StackState`로 표현한다.
- sheet/fullScreen/search처럼 동시에 하나만 떠야 하는 흐름은 `MainTabFeature.Destination`과 `@Presents`로 표현한다.
- `@Presents`는 State 안에 여러 개를 직접 나열하지 않고 `@Reducer enum Destination`의 단일 optional state로 사용한다.

### Feature Coordinator

feature coordinator는 feature root를 조립하고, feature에서 올라온 intent를 상위 coordinator로 전달하던 레거시 adapter다.

현재 MainTab 아래에서 feature coordinator는 대부분 root factory와 navigation adapter 역할을 하며, 단계적으로 제거 대상이다. 상위 handler가 없을 때만 독립 실행이나 demo를 위해 자기 local path로 fallback할 수 있다.

예:

- `HomeCoordinator.onSelectPopup`
- `HomeCoordinator.onSearch`
- `HomeCoordinator.onShowComingPopups`
- `ProfileCoordinator.onProfileSetting`
- `ProfileCoordinator.onNotification`
- `ProfileCoordinator.onServiceTerms`

대체 목표:

- feature view initializer에 화면 전환용 `@escaping` closure를 새로 추가하지 않는다.
- feature reducer는 `.delegate(...)` action으로 navigation intent를 parent에 올린다.
- parent reducer가 `path.append(...)` 또는 `destination = ...`로 실제 화면 전환을 결정한다.

## NavigationStack 규칙

- active main flow에서는 App 모듈의 `MainTabFeatureView`가 TCA `StackState`와 `@Presents` destination을 사용해 navigation을 소유한다.
- legacy main flow에서는 `MainTabCoordinatorView`가 단일 `NavigationStack(path: $coordinator.paths)`를 가진다.
- 탭 root view는 중첩 `NavigationStack`을 만들지 않는다.
- onboarding처럼 main flow와 분리된 독립 흐름도 최종적으로 `AuthFlowFeature` tree-based navigation으로 전환한다.
- fullScreen 안에서 닫히는 독립 화면은 자체 stack을 가질 수 있다.

## Bottom Sheet 규칙

맵 bottom sheet는 `MapFeatureView`와 `MapFeatureCompound`가 소유한다.

이유:

- sheet position, selected popup, region/sort/detail sheet type이 모두 맵 화면 내부 상태다.
- coordinator에 올리면 route가 화면 로컬 상태를 과하게 알게 된다.
- V0와 동일하게 실제 bottom sheet 동작은 `BottomSheet` 라이브러리 기반으로 유지한다.

따라서 `MapCoordinator`에는 임시 `safeAreaInset` bottom sheet host를 두지 않는다.

전역 bottom sheet가 필요하면 TCA `Destination` state로 모델링한다.

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
2. root/auth/sheet/fullScreen이면 tree-based `Destination` 영향을 먼저 본다.
3. push/drill-down이면 stack-based `Path` 영향을 먼저 본다.
4. feature에는 화면 전환 callback을 추가하지 않고 delegate action을 추가한다.
5. active 경로에서는 TCA view의 destination builder가 path/destination state를 실제 view로 변환한다.
6. feature 안에서만 닫히는 UI state는 feature state에 둔다.
7. legacy coordinator를 수정해야만 하는 경우에는 제거 계획과 함께 최소 범위로만 수정한다.

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

`MainTabCoordinator`는 메인 flow의 V0 MainCoordinator 역할을 맡았던 legacy 구조다. 현재는 App의 `MainTabFeature`로 대체하는 중이며, feature coordinator는 제거 대상으로 본다.

## 제거 순서

1. `AppFeature`로 root flow를 대체한다.
2. `MainTab`, `MainTabSession` 같은 App navigation 타입을 Coordinator 밖으로 옮긴다.
3. App target의 `Coordinator` 의존성을 제거한다.
4. `MainTabCoordinator`와 feature coordinator 활성 경로를 제거한다.
5. feature별 화면 전환용 escaping closure를 reducer delegate action으로 교체한다.
6. `Projects/Coordinator` 모듈과 workspace/project 의존성을 제거한다.
