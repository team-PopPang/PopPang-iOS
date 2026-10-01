# PopPangListKit

이 문서는 PopPangListKit으로 목록 화면을 만드는 기준이다. 목록 화면이나 셀을 추가·수정하기 전에 읽는다.

라이브러리 자체의 API와 동작은 [PopPangListKit 저장소](https://github.com/team-PopPang/PopPangListKit)의 README가 원본이다. 이 문서는 PopPang에서 쓰는 방식과 지켜야 할 규칙을 정리한다.

## 목차

- [개요](#개요)
- [연결 방법](#연결-방법)
- [기본 구조](#기본-구조)
- [식별자 규칙](#식별자-규칙)
- [레이아웃 규칙](#레이아웃-규칙)
- [Header·Footer 규칙](#headerfooter-규칙)
- [갱신 규칙](#갱신-규칙)
- [이벤트를 Store로 보내기](#이벤트를-store로-보내기)
- [페이지네이션](#페이지네이션)
- [이미지와 프리패치](#이미지와-프리패치)
- [UIKit Component 작성](#uikit-component-작성)
- [파일 배치와 이름](#파일-배치와-이름)
- [검증](#검증)
- [라이브러리를 고쳐야 할 때](#라이브러리를-고쳐야-할-때)
- [알려진 문제](#알려진-문제)

## 개요

| 항목 | 값 |
| --- | --- |
| 저장소 | `team-PopPang/PopPangListKit` |
| 버전 | 앱은 `1.1.0`을 쓴다(`Tuist/Package.swift`에서 `exact`로 고정). 라이브러리 최신 릴리즈는 `1.1.1`이다(2026-10-01 확인). |
| 관리 | 우리 팀이 만들고 관리하는 라이브러리다. 문제가 라이브러리에 있으면 [라이브러리를 고쳐야 할 때](#라이브러리를-고쳐야-할-때) 절차로 직접 고친다. |
| 의존성 | DifferenceKit |
| 연결 위치 | `Projects/Shared/ThirdParty/Project.swift`의 `.external(name: "PopPangListKit")` |
| 사용하는 곳 | `HomeFeatureV2`(앱), `AlertFeature` Demo(페이지네이션 실험) |

PopPangListKit은 SwiftUI에서 쓰지만 내부는 UIKit이다.

```text
PopPangList (SwiftUI View)
→ UIViewControllerRepresentable
→ PopPangListViewController (UICollectionView + compositional layout)
→ CollectionViewAdapter (DifferenceKit diff → batch update)
→ SwiftUI 셀은 UIHostingController로 감싸서 표시
```

- 첫 snapshot은 전체 reload, 이후에는 이전 snapshot과 diff해 batch update한다.
- 변경이 많거나(기본 100개 초과) 화면에 붙어 있지 않으면 전체 reload로 바꾼다.
- 갱신 중에 새 snapshot이 오면 가장 최신 것 하나만 대기열에 남긴다.

`HomeFeature`는 다른 라이브러리인 `ListKit`(`indextrown/Listkit`)을 쓰고, 앱에서는 쓰이지 않는다. 새 목록 화면은 PopPangListKit으로 만든다.

## 연결 방법

- feature는 `ThirdParty`에 의존하고 view 파일에서만 `import PopPangListKit`한다. feature `Project.swift`에 `.external(name: "PopPangListKit")`을 직접 추가하지 않는다.
- reducer 파일에서는 import하지 않는다. reducer는 목록 라이브러리를 몰라야 한다.
- SwiftUI의 `Section`과 이름이 겹치므로 반환 타입과 모호한 곳에서는 `PopPangListKit.Section`, `PopPangListKit.Cell`로 쓴다.

## 기본 구조

`PopPangList` 안에 `Section`을 나열하고, `Section` 안에 `For` 또는 `Cell`을 둔다. 실제 홈 화면(`HomeFeatureV2/Sources/Presentation/Home/HomeFeatureView.swift`)의 구조다.

```swift
@State private var listProxy = ListProxy()

PopPangList(proxy: listProxy) {
    bestPopupSection(popups: store.bestPopups) { popup in
        store.send(.popupSelected(popup))
    }
    comingPopupSection(popups: store.comingPopups) { popup in
        store.send(.popupSelected(popup))
    }
    gridPopupSection { popup in
        store.send(.popupSelected(popup))
    }
}
.scrollOverlay(alignment: .bottomTrailing, visibleWhen: .relativeToViewport(1.5)) { isVisible in
    HomeTopAnchorButton(isVisible: isVisible) {
        listProxy.scrollToSection(id: "grid", position: .top, animated: true)
    }
}
```

section은 view extension의 private 함수로 만든다.

```swift
// MARK: - BestPopup Section
extension HomeFeatureView {
    private func bestPopupSection(
        popups: [Popup],
        onTap: @escaping (Popup) -> Void
    ) -> PopPangListKit.Section {
        Section(id: "best") {
            For(popups, id: \.popupUuid) { popup in
                BestPopupCell(popup: popup)
            }
            .didSelect { popup in
                onTap(popup)
            }
            .layoutMode(.fitContent(estimatedSize: BestPopupCell.layoutSize))
        }
        .withHeader(item: store.nickname) { nickname in
            HomeBestHeader(nickname: nickname)
        }
        .headerBackground(UIColor(Color.subWhite))
        .disablesUpdateAnimation()
        .withSectionLayout(
            HorizontalLayout(spacing: 15, scrollingBehavior: .continuousGroupLeadingBoundary)
                .insets(.init(top: 0, leading: .contentPadding, bottom: 50, trailing: .contentPadding))
                .headerPinToVisibleBounds(true)
        )
    }
}
```

| 구성 요소 | 역할 |
| --- | --- |
| `PopPangList` | SwiftUI 진입점. `proxy`, `prefetchingPlugins`, list 이벤트(`onReachEnd`, `onRefresh`, `didScroll` 등)를 받는다. |
| `Section(id:)` | 셀 묶음, header·footer, 레이아웃 단위 |
| `For(data, id:)` | 데이터 배열을 SwiftUI 셀로 반복한다. 요소는 `Equatable`이어야 한다. |
| `Cell(id:component:)` | UIKit `Component` 하나를 셀로 만든다. SwiftUI 내용용 `Cell(id:item:layoutMode:content:)`도 있다. |
| `ListProxy` | 코드로 스크롤한다(`scrollToTop`, `scrollToSection(id:position:animated:)`). `@State`로 보관한다. |
| `scrollOverlay` | 일정 거리 이상 스크롤하면 overlay를 보여 준다. |

## 식별자 규칙

- section `id`는 목록 안에서 유일해야 한다. `ListProxy.scrollToSection(id:)`도 이 id를 쓴다.
- 셀 id는 같은 section 안에서만 유일하면 된다. 중복되면 Debug 빌드에서 assertion이 난다.
- 서버 데이터를 합칠 때는 reducer에서 중복 id를 제거한다. AlertFeature Demo의 `removingDuplicatePopupUuids()`, `appendUniquePopups(_:)`가 예다.
- 셀을 다른 section으로 옮기면 삭제 후 삽입으로 처리된다.

## 레이아웃 규칙

모든 section은 `withSectionLayout`을 호출해야 한다. 빠지면 assertion이 난다. 레이아웃마다 셀의 `layoutMode`를 맞춘다.

| 레이아웃 | 맞는 `layoutMode` | PopPang 사용처 |
| --- | --- | --- |
| `HorizontalLayout(spacing:scrollingBehavior:)` | `.fitContent(estimatedSize:)`. paging 동작을 쓰면 모든 셀이 같은 모드여야 한다. | 홈 best(`.continuousGroupLeadingBoundary`), coming(`.groupPaging`) |
| `VerticalLayout(spacing:)` | `.flexibleHeight(estimatedHeight:)` | AlertFeature Demo |
| `VerticalGridLayout(numberOfItemsInRow:itemSpacing:lineSpacing:)` | `.flexibleHeight(estimatedHeight:)` | 홈 grid (2열) |

- 크기가 고정된 SwiftUI 셀은 `static let layoutSize` 또는 `static let estimatedHeight`를 두고, view에도 같은 `.frame`을 준다. hosting 셀은 제안된 너비와 무제한 높이로 측정되기 때문이다.
- `GridPopupCell`의 너비 계산(`(화면 너비 - contentPadding * 2 - 15) / 2`)은 grid의 `itemSpacing: 15`와 insets에 맞춰져 있다. 둘 중 하나를 바꾸면 다른 쪽도 고친다.
- 모든 레이아웃은 `.insets(_:)`, `.headerPinToVisibleBounds(_:)`, `.footerPinToVisibleBounds(_:)`를 쓸 수 있다.

## Header·Footer 규칙

- `withHeader(item:)`의 `item`에는 header가 실제로 보여 주는 값을 넣는다. header는 `item`이 바뀔 때만 다시 그려진다.
  - 예전 홈 header는 `item: "bestPopup"`이라서 닉네임이 바뀌어도 갱신되지 않았다(`fced603`에서 `item: store.nickname`으로 고침).
  - 고정 문자열 `item`은 header가 `HomeFilterHeader(store:)`처럼 store를 직접 관찰하거나, closure 안에서 store를 읽을 때만 쓴다.
- `item` 없는 header·footer는 snapshot마다 section 전체를 다시 불러온다. 표시 데이터를 `item`으로 넘기는 쪽을 쓴다.
- `.headerBackground(_:)`는 `.withHeader` 뒤에 호출한다. 순서가 바뀌면 assertion이 난다.
- 셀이 하나도 없는 section은 header까지 표시되지 않고, `scrollToSection`도 `false`를 반환한다.

## 갱신 규칙

- diff는 `For` 요소나 `item`, 그리고 `reuseIdentifier`만 비교한다. closure는 비교하지 않는다.
- 그래서 셀이 표시하는 값은 모두 요소 안에 있어야 한다. 요소가 바뀌지 않으면 셀은 다시 그려지지 않는다.
- 셀에 넘기는 closure는 `store`와 변하지 않는 id만 캡처한다. reducer는 받은 id로 최신 모델을 다시 찾는다(`HomeFeature.currentPopup(in:popupUuid:)`).
- SwiftUI에서 갱신은 기본으로 animation이 붙는다. 특정 section만 끄려면 `.disablesUpdateAnimation()`을 쓴다.
- `.scrollOverlay`는 `some View`를 반환하므로 `PopPangList`의 다른 modifier를 모두 붙인 뒤 마지막에 둔다.
- Toggle처럼 셀 안에서 값을 바꾸는 컨트롤은 `Binding<Item>`을 받는 `Cell` initializer를 쓴다.

## 이벤트를 Store로 보내기

| 이벤트 | 방법 | 예 |
| --- | --- | --- |
| 셀 탭 | `For.didSelect { element in ... }`에서 `store.send` | `store.send(.popupSelected(popup))` |
| 셀 안의 버튼 | 셀에 UI 이벤트 closure를 넘기고 closure에서 `store.send` | `GridPopupCell(popup:toggleLike: { store.send(.favoriteToggleTapped(popupUuid: popup.popupUuid)) })` |
| 광고 같은 다른 종류의 셀 | `didSelect`에서 case를 거른다 | `guard case let .content(popup, _) = item else { return }` |
| 다른 화면으로 이동 | reducer가 delegate action으로 올린다 | [TCA Navigation](tca-navigation.md) |

셀 하나에는 이벤트 종류마다 handler를 하나만 둔다. 화면 전환용 `@escaping` closure를 새로 만들지 않는다. `ComingPopupDetailFeatureView`에는 화면 전환용 `onSelectPopup` closure가 남아 있으므로, 이 화면을 고칠 때 delegate action으로 바꾼다.

## 페이지네이션

`onReachEnd`로 다음 페이지를 요청한다. 같은 위치에서 여러 번 호출될 수 있으므로 reducer에서 막는다.

```swift
// View (AlertFeature Demo)
PopPangList { ... }
    .onReachEnd(offsetFromEnd: .relativeToContainerSize(multiplier: 0.75)) { _ in
        store.send(.reachedEnd)
    }

// Reducer
case .reachedEnd:
    guard state.hasStarted,
          state.hasNext,
          !state.isRequesting,
          state.errorMessage == nil,
          let cursor = state.nextCursor
    else {
        return .none
    }
    state.isLoadingNextPage = true
    return requestPage(userUuid: state.userUuid, cursor: cursor)
```

새 페이지를 합칠 때는 기존 id와 겹치는 항목을 제거한다. 현재 앱 홈은 페이지네이션 없이 grid 전체를 한 번에 불러온다.

## 이미지와 프리패치

- SwiftUI 셀은 Kingfisher `KFImage`로 이미지를 그린다. 크기는 DSKit의 `downSampled(_:)` helper(`KFImage+DSKit.swift`)로 맞춘다.
- PopPangListKit은 Kingfisher에 의존하지 않는다. 프리패치는 `RemoteImagePrefetching` protocol과 `RemoteImagePrefetchingPlugin`으로 한다.
- 프리패치는 `ComponentRemoteImagePrefetchable`을 채택한 UIKit `Component`에서만 동작한다. SwiftUI `For`·`Cell` 셀은 프리패치되지 않는다.
- Kingfisher로 프리패치하려면 `RemoteImagePrefetching`을 구현한 adapter가 필요하다. 현재 구현은 AlertFeature Demo의 URLSession 기반 pipeline뿐이다.

## UIKit Component 작성

성능 때문에 UIKit 셀이 필요하면 `Component`를 만든다. 이름은 `<Name>Component`로 짓는다.

```swift
private struct PopupPaginationListKitCardComponent: Component, ComponentRemoteImagePrefetchable {
    let item: PopupPaginationItem          // Equatable
    let imagePipeline: PopupPaginationImagePipeline

    var layoutMode: ContentLayoutMode {
        .flexibleHeight(estimatedHeight: 150)
    }

    var remoteImageURLs: [URL] {
        item.thumbnailURL.map { [$0] } ?? []
    }

    @MainActor
    func renderContent(coordinator: Void) -> PopupPaginationUIKitCardView {
        PopupPaginationUIKitCardView()
    }

    @MainActor
    func render(in content: PopupPaginationUIKitCardView, coordinator: Void) {
        content.configure(with: item, imagePipeline: imagePipeline)
    }
}
```

- `Item`은 `Equatable`이어야 하고, 셀이 표시하는 값을 모두 담는다.
- view는 한 번만 만들고 재사용할 때 `render(in:)`만 다시 호출된다. 이전 비동기 작업(이미지 요청 등)은 `render(in:)`에서 취소하거나 무시한다.
- 셀 크기는 view의 `sizeThatFits`로 측정하므로 content view에서 구현한다.
- `reuseIdentifier` 기본값은 타입 이름이다. `reuseIdentifier`가 바뀌면 제자리 갱신 대신 reload된다.

## 파일 배치와 이름

`HomeFeatureV2` 기준이다.

```text
Sources/Presentation/<Screen>/
├── <Screen>Feature.swift          reducer (PopPangListKit import 없음)
├── <Screen>FeatureView.swift      PopPangList와 section helper
└── UI/
    ├── Cell/                      <Name>Cell (SwiftUI 셀)
    ├── Header/                    <Screen><Name>Header
    ├── Button/
    └── NavigationBar/
```

- section helper는 `// MARK: - <Name> Section` extension에 둔다.
- SwiftUI 셀 이름은 `<Name>Cell`, UIKit 셀 모델은 `<Name>Component`로 짓는다.

## 검증

- 목록 자체에는 앱 저장소의 unit test가 없다. reducer 상태 변화는 TestStore로 테스트한다. ([테스트](../development/testing.md))
- 화면 동작은 `HomeFeatureV2Demo` 앱이나 AlertFeature Demo의 "05 PopPangListKit" 경로에서 확인한다.
- 라이브러리 동작 자체를 바꿔야 하면 앱 코드로 우회하지 않고 아래 [라이브러리를 고쳐야 할 때](#라이브러리를-고쳐야-할-때) 절차를 따른다.

## 라이브러리를 고쳐야 할 때

PopPangListKit은 우리 라이브러리다. 앱을 개발하다가 원인이 라이브러리 안에 있으면, 앱에서 우회하지 않고 라이브러리를 고친다. 라이브러리 수정과 PR도 이 프로젝트 작업 안에서 진행한다.

### 1. 원인이 라이브러리에 있는지 가린다

| 앱에서 고친다 | 라이브러리에서 고친다 |
| --- | --- |
| 셀 id 중복, `layoutMode`와 레이아웃 불일치, header `item` 누락처럼 사용법이 이 문서와 다른 경우 | 사용법이 맞는데 diff·갱신·레이아웃·크기 측정·이벤트 전달이 잘못 동작하는 경우 |
| reducer 상태나 데이터 문제 | 같은 문제가 라이브러리 Demo나 테스트에서도 재현되는 경우 |

`reloadData` 강제, 의미 없는 id 변경, 지연 호출처럼 라이브러리 버그를 앱 코드로 덮는 우회는 하지 않는다.

원인을 확인할 때는 읽기만 한다. 앱이 쓰는 버전(`1.1.0`)의 소스는 GitHub에서 볼 수 있다.

```bash
gh api "repos/team-PopPang/PopPangListKit/contents/Sources/PopPangListKit?ref=1.1.0" --jq '.[].name'
```

### 2. 멈추고 승인을 받는다

라이브러리에서 고쳐야 한다고 판단하면 작업을 멈추고 아래 형식으로 묻는다. 승인 전에는 라이브러리 저장소에 브랜치·커밋·이슈를 만들지 않는다.

```text
PopPangListKit에서 고쳐야 할 부분을 찾았습니다.

- 증상: <앱에서 보이는 문제와 재현 조건>
- 원인: <라이브러리 파일과 동작> (앱이 쓰는 버전 1.1.0 기준)
- 수정 방향: <라이브러리에서 바꿀 내용>
- 앱 영향: 라이브러리 PR 병합 → 새 버전 릴리즈 → 앱의 Tuist/Package.swift 버전 변경이 필요합니다.
- 이슈: 라이브러리 저장소에 이슈를 만들까요? (만들면 브랜치가 자동 생성됩니다)

이 부분을 고쳐야 합니다. 승인하시겠습니까?
```

### 3. 승인 후 이 프로젝트에서 진행한다

| 단계 | 할 일 |
| --- | --- |
| 저장소 받기 | 앱 저장소 밖(옆 폴더)에 받는다: `gh repo clone team-PopPang/PopPangListKit ../PopPangListKit`. 이미 있으면 `git -C ../PopPangListKit switch main && git -C ../PopPangListKit pull --ff-only`. 앱 저장소 안에 받지 않는다. |
| 이슈·브랜치 | 라이브러리도 앱과 같은 규칙을 쓴다(`.github/issue-branch.yml`). 이슈를 assign하면 `fix/#<번호>` 같은 브랜치가 자동 생성되고, 받아서 작업한다. 이슈 없이 진행하기로 했으면 `fix/<짧은-설명>` 브랜치를 만든다. |
| 수정 | 라이브러리 README의 규칙과 기존 코드를 따른다. 동작을 바꾸면 라이브러리 README도 함께 고친다. |
| 라이브러리 테스트 | 라이브러리에는 테스트 CI가 없다. 로컬에서 실행한다. iOS 전용 패키지라 `swift test`는 쓰지 않는다. |
| 앱에서 확인 | 필요하면 앱의 `Tuist/Package.swift`에서 PopPangListKit 줄을 잠시 `.package(path: "../../PopPangListKit")`로 바꾸고 `tuist install` → `tuist generate` 후 화면을 확인한다. 확인이 끝나면 원래 `exact` 버전으로 되돌린다. 이 임시 변경은 커밋하지 않는다. |
| 커밋·PR | 라이브러리 저장소에서 [Git 작업 흐름](../development/gitflow.md)과 같은 규칙으로 커밋한다. 라이브러리의 `.github/PULL_REQUEST_TEMPLATE.md`로 본문을 쓰고 `gh pr create --repo team-PopPang/PopPangListKit --base main`으로 올린다. AI 작성 표기는 넣지 않는다. |
| 릴리즈 | PR이 병합되면 라이브러리의 `new-release.yml` workflow(수동 실행, version 입력)로 새 버전 태그를 만든다. 사용자가 요청할 때만 실행한다. |
| 앱 반영 | 앱의 `Tuist/Package.swift`에서 `exact:` 버전을 새 버전으로 바꾸고 `tuist install`로 `Tuist/Package.resolved`를 갱신한다. 의존성 변경이므로 앱 저장소에서 따로 계획·승인·커밋·PR한다. 이 문서의 버전도 고친다. |

라이브러리 테스트 명령(라이브러리 폴더에서 실행):

```bash
xcodebuild test -scheme PopPangListKit -destination 'platform=iOS Simulator,name=iPhone 17'
```

- 2026-10-01에 Xcode 27.0, iPhone 17(iOS 27.0) 시뮬레이터로 실행해 107개 테스트(15개 suite)가 통과했다.
- 시뮬레이터는 설치된 Xcode의 iOS SDK 버전으로 고른다. 같은 Mac에서 iOS 18.3 시뮬레이터(`iPhone 16`)를 지정하면 `Unable to find a device matching the provided destination specifier`로 실패했다.
- 사용할 수 있는 시뮬레이터는 `xcrun simctl list devices available`로 확인한다.
- 화면 동작은 라이브러리의 `Demo/PopPangListKitDemo.xcodeproj`에서도 확인할 수 있다.

### 하지 않는 것

- 승인 없이 라이브러리 저장소에 push하거나 PR을 만들지 않는다.
- 라이브러리 소스를 앱 저장소에 복사하거나 앱 저장소 안에 clone하지 않는다.
- 로컬 경로(`.package(path:)`)로 바꾼 `Tuist/Package.swift`를 커밋하지 않는다.
- 라이브러리 수정과 앱 기능 변경을 한 PR에 섞지 않는다.

## 알려진 문제

| 위치 | 내용 |
| --- | --- |
| `HomeFeatureView.swift` coming section | section id가 `"comming"`으로 적혀 있다. 이 id로 스크롤할 때 철자를 맞춘다. |
| `HomeFeature` grid | 서버 응답의 `gridPopups`에서 중복 `popupUuid`를 제거하지 않는다. 중복이 오면 Debug assertion이 날 수 있다. |
| `ThirdParty` | `HomeFeature`가 쓰는 `ListKit`도 함께 링크되어 있다. |
| HomeFeatureV2 셀 파일 | 파일 헤더 주석의 파일 이름(`ListKit*Cell.swift`)이 실제 이름과 다르고, `GridPopupCell.swift`에 주석 처리된 코드가 있다. |

## 관련 문서

- [TCA Feature 작성 규칙](tca-feature.md)
- [TCA Navigation](tca-navigation.md)
- [모듈 구조](modules.md)
- [PopPangListKit README](https://github.com/team-PopPang/PopPangListKit)
