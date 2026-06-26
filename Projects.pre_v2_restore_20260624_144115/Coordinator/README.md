# Coordinator Guide

## 현재 기준

이 모듈의 coordinator 인스턴스는 앱 전역에 `RootCoordinator` 하나만 둔다.

- `RootCoordinator`가 root 전환, tab 선택, push route, fullScreen, sheet, overlay, bottomSheet 상태를 직접 소유한다.
- main flow feature view는 feature별 `*FeatureInterface` 라우터 프로토콜을 통해 navigation intent를 올리고, 실제 route 해석은 `RootCoordinator`가 맡는다.
- route는 가벼운 값만 담고 `Binding`, `View`, 무거운 closure를 넣지 않는다.
- feature 화면 내부 상태는 계속 feature state에 둔다.

## 흐름 소유권

### RootCoordinator

다음 상태를 모두 소유한다.

- launch
- onboarding
- auth
- register
- main
- selected tab
- `routes: [MainTabRoute]`
- `fullScreen: MainTabFullScreenRoute?`

### Main Flow

메인 플로우는 `MainTabCoordinatorView`가 렌더링하지만, 상태 소유자는 여전히 `RootCoordinator`다.

- `NavigationStack(path: $coordinator.routes)` 하나만 사용한다.
- 탭 root view는 중첩 `NavigationStack`을 만들지 않는다.
- 탭 root 조립도 `RootCoordinator`가 직접 한다.

## Bottom Sheet 규칙

맵 bottom sheet는 계속 `MapFeatureView`와 feature state가 소유한다.

- sheet position, selected popup, sheet type은 화면 로컬 상태다.
- 전역 bottom sheet가 필요할 때만 coordinator 상태를 쓴다.

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
- 화면 runtime state는 feature state나 `RootCoordinator` state에 둔다.
- `Binding`, `View`, closure container는 route에 넣지 않는다.

## 새 흐름 추가 체크리스트

1. 앱 루트 전환인지, main flow 전역 이동인지, feature 로컬 상태인지 먼저 정한다.
2. main flow 전역 이동이면 `MainTabRoute` 또는 `MainTabFullScreenRoute`에 case를 추가한다.
3. feature view는 feature별 interface router를 통해 route intent만 전달하게 하고, `RootCoordinator`가 이를 실제 route로 해석하게 한다.
4. `RootCoordinator` 또는 `MainTabCoordinatorView`에서 route를 실제 view로 변환한다.
5. feature 안에서만 닫히는 UI state는 feature state에 둔다.

## 현재 구조 요약

```text
RootCoordinator
 -> root (launch/onboarding/auth/register/main)
 -> selectedTab
 -> routes
 -> fullScreen
```
