# SheetKit

이 문서는 SheetKit으로 화면 위에 하단 시트를 붙이는 기준이다. 시트를 새로 붙이거나 SheetKit을 고치기 전에 읽는다.

시트를 붙이기만 할 때는 [공개 API](#공개-api)부터 [상태를 둘 곳](#상태를-둘-곳)까지 읽으면 된다. 그 아래 [동작](#동작)과 [시스템 시트와 다른 점](#시스템-시트와-다른-점)은 시트가 어떻게 움직이는지, [SheetKit을 고칠 때 지킬 것](#sheetkit을-고칠-때-지킬-것)과 [검증](#검증)은 SheetKit을 고치는 사람을 위한 내용이다.

## 목차

- [개요](#개요)
- [공개 API](#공개-api)
- [연결 방법](#연결-방법)
- [기본 사용](#기본-사용)
- [내용이 바뀌는 시트](#내용이-바뀌는-시트)
- [시트 높이 받기](#시트-높이-받기)
- [시트 안에서 끌기](#시트-안에서-끌기)
- [높이 단계](#높이-단계)
- [모양](#모양)
- [상태를 둘 곳](#상태를-둘-곳)
- [동작](#동작)
- [시스템 시트와 다른 점](#시스템-시트와-다른-점)
- [SheetKit을 고칠 때 지킬 것](#sheetkit을-고칠-때-지킬-것)
- [검증](#검증)

## 개요

| 항목 | 값 |
| --- | --- |
| 위치 | `Projects/Shared/SheetKit` |
| product | `.framework`. DSKit과 feature가 함께 링크하므로 코드가 두 번 들어가지 않게 동적 framework로 둔다. |
| 의존성 | 없음(SwiftUI만). 다른 앱에서도 쓸 수 있게 DSKit, TCA, Core를 import하지 않는다. |
| 타깃 | `SheetKit`, `SheetKitTests`, `SheetKitDemo` |
| 폴더 | `Sources/Public/`(쓰는 쪽이 보는 API), `Sources/Internal/`(구현), `Resources/`(VoiceOver 문구) |
| 쓰는 곳 | `MapFeatureView`의 팝업 목록 시트와 지역·정렬·미리보기 시트, 시트 위를 따라 움직이는 내 위치 버튼 |

지도 화면은 서드파티 라이브러리 BottomSheet를 쓰다가 SheetKit으로 바꿨다(이슈 #110). BottomSheet는 숨김과 높이를 한 enum에 섞어 쓰고, 화면이 다시 그려질 때마다 시트 전체에 애니메이션을 걸었다. SheetKit은 이 두 가지를 하지 않는다.

## 공개 API

SheetKit 밖에서 쓰는 것은 아래뿐이다. 높이 계산, 끌기 처리, 겹친 시트 연결 같은 나머지 타입은 모두 `internal`이라 SheetKit 밖에서는 보이지 않는다. 쓰는 쪽은 이 표만 알면 된다.

코드에서는 `Sources/Public/` 폴더만 보면 된다. 파일마다 공개 선언과 `Internal/` 타입에 넘기는 짧은 본문만 있다.

```text
Sources/
├── Public/      쓰는 쪽이 보는 API
│   ├── View+BottomSheet.swift            bottomSheet(detent:...), bottomSheet(item:detent:...)
│   ├── BottomSheetDetent.swift           .medium, .large, .fraction(_:), .height(_:)
│   ├── View+BottomSheetAppearance.swift  bottomSheetTopInset(_:), bottomSheetBackground(_:), bottomSheetCornerRadius(_:)
│   ├── View+BottomSheetDragHandle.swift  bottomSheetDragHandle(_:)
│   └── BottomSheetGeometry.swift         BottomSheetGeometry, onBottomSheetGeometryChange(_:)
└── Internal/    구현. 쓰는 쪽은 몰라도 된다.
```

| 분류 | API | 하는 일 | 설명 |
| --- | --- | --- | --- |
| 시트 붙이기 | `bottomSheet(detent:detents:content:)` | 높이 바인딩이 `nil`이면 숨는 시트를 붙인다. 가장 낮은 단계보다 아래로 끌면 `nil`이 된다. | [기본 사용](#기본-사용) |
| 시트 붙이기 | `bottomSheet(item:detent:detents:content:)` | `item`이 있을 때만 보이는 시트를 붙인다. 끌어서는 숨지 않는다. | [내용이 바뀌는 시트](#내용이-바뀌는-시트) |
| 높이 단계 | `BottomSheetDetent`(`.medium`, `.large`, `.fraction(_:)`, `.height(_:)`) | 시트가 멈출 높이 | [높이 단계](#높이-단계) |
| 시트 높이 | `onBottomSheetGeometryChange(_:)`, `BottomSheetGeometry` | 시트 높이를 끄는 동안에도 프레임마다 받는다. 시트 위에 띄운 버튼을 옮길 때 쓴다. | [시트 높이 받기](#시트-높이-받기) |
| 끌기 | `bottomSheetDragHandle(_:)` | 이 뷰를 끌어도 시트가 움직이게 한다. 목록 밖의 제목 줄 같은 곳에 붙인다. | [시트 안에서 끌기](#시트-안에서-끌기) |
| 모양 | `bottomSheetTopInset(_:)`, `bottomSheetBackground(_:)`, `bottomSheetCornerRadius(_:)` | `.large`일 때 시트 위 여백, 배경, 위쪽 모서리 반지름 | [모양](#모양) |

## 연결 방법

1. 시트를 붙일 모듈의 `Project.swift`에 의존성을 추가한다.

   ```swift
   .project(target: "SheetKit", path: "../../Shared/SheetKit"),
   ```

2. 시트를 붙이는 파일에서 `import SheetKit`을 한다. PopPang 모양을 입힐 때는 `import DSKit`도 한다.

## 기본 사용

```swift
@State private var detent: BottomSheetDetent? = .medium

Map()
    .bottomSheet(detent: $detent) {
        PlaceList()
    }
    .ppBottomSheetStyle()
```

- `detent`가 `nil`이면 시트를 숨긴다. 다시 보이려면 `detent = .medium`처럼 값을 넣는다. 상태만 바꾸면 시트가 알아서 애니메이션한다.
- 가장 낮은 단계보다 아래로 끌어 내리면 `detent`가 `nil`이 되어 시트가 숨는다.
- 높이 단계를 넘기지 않으면 `[.medium, .large]`를 쓴다.

## 내용이 바뀌는 시트

시스템 `.sheet(item:)`과 같은 모양이다.

```swift
@State private var option: Option?                       // Identifiable
@State private var optionDetent: BottomSheetDetent = .medium

content
    .bottomSheet(item: $option, detent: $optionDetent) { option in
        OptionView(option: option)
    }
```

- `item`이 `nil`이면 시트를 숨긴다.
- 높이 바인딩이 Optional이 아니므로 끌어서는 닫히지 않고 높이만 바뀐다. 닫으려면 `item`을 `nil`로 바꾼다.
- 시트가 열린 채로 `item`이 바뀌면 높이는 그대로 두고 내용만 새로 만든다.

정리하면, **높이 바인딩이 Optional이면 끌어서 숨길 수 있고, Optional이 아니면 숨길 수 없다.**

시트를 여러 장 붙이면 나중에 붙인 시트가 위에 그려진다. 지도 화면은 목록 시트 위에 지역·정렬·미리보기 시트를 이렇게 겹친다.

위 시트를 끄는 동안에는 아래 시트도 같은 거리만큼 같이 움직인다. 손을 떼면 시트마다 자기 높이 단계에 멈추므로, 두 시트를 같은 높이에 두려면 쓰는 쪽에서 위 시트의 높이를 아래 시트에 넣는다.

```swift
.onChange(of: optionDetent) { _, detent in
    listDetent = detent
}
```

## 시트 높이 받기

지도의 내 위치 버튼처럼 시트 위쪽 끝을 따라 움직일 뷰는 `onBottomSheetGeometryChange(_:)`로 시트 높이를 받아 쓰는 쪽에서 옮긴다. 버튼은 하나만 둔다. 시트를 숨기면 높이가 0이 되므로 같은 버튼이 바닥 자리로 내려간다.

```swift
@Observable final class SheetPosition {
    var geometry: BottomSheetGeometry?
}

@State private var sheetPosition = SheetPosition()

Map()
    .overlay(alignment: .bottomTrailing) {
        // geometry.height만큼 올려 그리는 작은 뷰. 이 뷰만 다시 그려진다.
        LocationButtonLayer(position: sheetPosition)
    }
    .bottomSheet(detent: $detent) {
        PlaceList()
    }
    .onBottomSheetGeometryChange { geometry in
        sheetPosition.geometry = geometry
    }
```

| 값 | 내용 |
| --- | --- |
| `height` | 시트를 붙인 뷰의 바닥에서 시트 위쪽 끝까지의 높이. 시트가 숨으면 0이다. |
| `maxHeight` | `.large` 높이. 끝까지 올리기 전에 버튼을 흐리게 할 때 쓴다. |

- 끄는 동안과 높이 단계를 옮기는 애니메이션 동안에도 프레임마다 불려, 버튼이 시트와 같은 프레임에 움직인다.
- 시트를 여러 장 겹치면 가장 높이 올라온 시트의 높이를 넘긴다. 위에 겹친 시트를 끌 때도 버튼이 따라간다.
- 프레임마다 불리므로 받은 값을 화면의 `@State`에 담지 않는다. 작은 `@Observable` 객체에 담아 그 값을 읽는 뷰만 다시 그려지게 한다. 지도 화면은 `MapSheetPosition`에 담고 `MapLocationButtonLayer`만 다시 그린다.
- 받은 높이로 움직이는 뷰는 `overlay`에 두고 `offset`으로 옮긴다. 시트를 붙인 뷰의 크기 계산에 끼우면(`ZStack` 안에서 `padding`으로 올리기 등) 안 된다. 받은 높이가 그 뷰의 크기를 소수점 끝자리만큼 바꾸고, 시트가 그 크기로 높이를 다시 계산하는 고리가 생겨 레이아웃이 끝없이 반복된다. 1.1.8 지도 화면에서 시트를 높이 올리면 앱이 멈춘 원인이다(#122).
- 같은 고리가 생겨도 끝없이 돌지 않게, SheetKit은 부동소수점 계산 오차만큼(0.01pt 이하)만 바뀐 높이를 무시한다. 시트를 붙인 뷰의 높이는 바꾸지 않고, `onBottomSheetGeometryChange(_:)`는 높이와 최대 높이가 모두 0.01pt 이하로 바뀌면 부르지 않는다. 실제로 끌거나 멈춘 높이는 그보다 크게 바뀌어서 그대로 전달된다.
- 높이로 버튼을 흐리게 숨긴다면, 불투명도가 정확히 0이 될 때만 숨기지 말고 작은 값(지도 화면은 0.05) 이하에서 터치와 VoiceOver를 끈다.
- 시트를 숨겼을 때 버튼이 멈출 자리와 끝까지 올렸을 때 숨기는 방법은 쓰는 쪽이 정한다. 지도 화면은 시트를 숨기면 목록 보기 버튼 오른쪽에 멈추고, 끝까지 올리기 150pt 전부터 흐려지다 끝에서 숨는다.
- 시트를 붙인 화면은 그리는 도중 `UIWindow.safeAreaInsets` 같은 UIKit 값을 읽지 않는다. UIKit이 상태 바 설정을 SwiftUI에 되물어 그래프 순환이 생기고, 순환이 끊긴 자리의 화면이 갱신되지 않는다. 지도 화면은 창의 safe area를 읽다가 시트를 숨겨도 목록 보기 버튼이 나타나지 않았다. safe area는 `GeometryReader`의 `safeAreaInsets`로 읽는다. 이 값의 아래쪽에는 키보드 높이가 들어가므로, 키보드와 상관없는 창 값이 필요하면 `onChange`처럼 그리기가 끝난 뒤 불리는 곳에서 읽어 둔다. 지도 화면은 탭바 높이를 이렇게 구한다.

## 시트 안에서 끌기

시트를 끄는 곳과 목록을 스크롤하는 곳을 나눈다. 목록 위에서 시작한 끌기는 언제나 목록만 스크롤하고, 시트는 반응하지 않는다.

| 끌기를 시작한 곳 | 동작 |
| --- | --- |
| 손잡이 줄 | 시트가 움직인다. |
| 내용이 터치를 받지 않는 빈 곳(여백, `Spacer`) | 시트가 움직인다. |
| `bottomSheetDragHandle()`을 붙인 뷰 | 시트가 움직인다. 안쪽 버튼은 탭을 그대로 받고, 버튼 위에서 시작해 끌면 버튼은 눌리지 않고 시트가 움직인다. |
| 스크롤뷰, `List` | 목록만 스크롤한다. 목록이 맨 위일 때 아래로 끌어도 시트는 그대로다. |

제목 줄처럼 목록이 아닌 곳은 스크롤뷰 밖에 두고 `bottomSheetDragHandle()`을 붙인다.

```swift
.bottomSheet(detent: $detent) {
    VStack(spacing: 0) {
        SheetHeader()
            .bottomSheetDragHandle()

        ScrollView {
            PlaceList()
        }
    }
}
```

- 스크롤뷰나 `List` 안의 뷰에는 붙이지 않는다. 스크롤과 끌기가 경쟁한다.
- 목록이 아닌 내용도 작은 화면에서 시트를 넘칠 수 있으면 스크롤뷰로 감싸고, 끌기 손잡이는 제목 줄에만 붙인다. 지도 화면의 정렬·미리보기 시트가 이렇게 한다. 내용 전체에 붙이고 스크롤을 빼면, 작은 화면(iPhone SE)의 가운데 높이에서 내용 아래가 탭바에 가려 끝까지 볼 수 없게 된다.
- 가로로 시작한 끌기는 시트가 받지 않는다.
- 여러 곳을 동시에 끌면 먼저 시작한 한 곳만 시트를 움직인다.
- 목록을 끌어 시트까지 움직이는 동작(애플 지도 방식)은 넣지 않는다. 목록 위 끌기가 언제나 목록만 움직이게 하기 위해서다.

## 높이 단계

`BottomSheetDetent`는 struct다. 쓰는 쪽은 값을 넘기기만 하므로, SheetKit에 높이 종류를 더해도 쓰는 쪽 코드가 깨지지 않는다.

| 값 | 높이 |
| --- | --- |
| `.medium` | 시트를 붙인 뷰 높이의 절반 |
| `.large` | 시트를 붙인 뷰 높이에서 `bottomSheetTopInset(_:)`만큼 뺀 높이 |
| `.fraction(_:)` | 시트를 붙인 뷰 높이에 대한 비율 |
| `.height(_:)` | 고정 높이(pt) |

- 높이는 0보다 작거나 `.large`보다 클 수 없다.
- 이름 붙인 높이가 필요하면 쓰는 쪽에서 extension으로 만든다.

  ```swift
  extension BottomSheetDetent {
      static let peek: BottomSheetDetent = .fraction(0.2)
  }
  ```

- 비율이나 고정 높이로 표현할 수 없는 계산 방식이 필요해지면, SheetKit에 `.custom` 같은 종류를 추가한다. 쓰는 쪽 코드는 깨지지 않는다.

## 모양

모양은 environment로 넘긴다. 시트를 붙인 뷰나 그 상위 뷰에 한 번 붙이면 아래의 시트 모두에 적용된다.

| modifier | 기본값 | 하는 일 |
| --- | --- | --- |
| `bottomSheetTopInset(_:)` | 0 | `.large`일 때 시트 위에 남길 공간. 시트를 붙인 뷰의 위쪽 끝에서 잰다. |
| `bottomSheetBackground(_:)` | 시스템 배경색 | 시트 배경 |
| `bottomSheetCornerRadius(_:)` | 16 | 시트 위쪽 모서리 반지름 |

- PopPang 모양(흰 배경, 위쪽 모서리 30)은 DSKit의 `ppBottomSheetStyle()`로 한 번에 입힌다.
- 손잡이는 36×5 막대이고 시스템 `tertiaryLabel` 색을 쓴다.

## 상태를 둘 곳

SheetKit은 `Binding`만 받으므로 상태를 어디에 둘지는 쓰는 화면이 정한다.

| 방식 | 연결 |
| --- | --- |
| view의 `@State` | `.bottomSheet(detent: $detent)` |
| TCA reducer | `Binding(get: { store.detent }, set: { store.send(.detentChanged($0)) })` 계산 프로퍼티. `BindingReducer`는 쓰지 않는다([TCA Feature 작성 규칙](tca-feature.md)). |
| `@Observable` 모델 | `.bottomSheet(detent: $model.detent)` |

PopPang에서는 시트 높이처럼 그 화면 안에서만 쓰는 상태를 view의 `@State`에 둔다. `MapFeatureView`도 시트 상태를 `@State`로 두고, 지역·구·정렬 선택만 reducer로 보낸다. 다른 화면에서 시트를 열어야 하거나 서버 응답을 받은 뒤 시트를 열고 닫아야 하면 그 상태만 reducer로 옮긴다.

## 동작

| 동작 | 내용 |
| --- | --- |
| 끌기 | 손잡이 줄(높이 20pt), 내용이 터치를 받지 않는 빈 곳, `bottomSheetDragHandle()`을 붙인 뷰를 끌 수 있다. 목록 위에서 시작한 끌기는 목록만 스크롤한다([시트 안에서 끌기](#시트-안에서-끌기)). |
| 멈출 높이 | 손을 뗀 높이에서 속도만큼 조금 더 간 높이를 구해 가장 가까운 단계에 멈춘다. 속도는 초속 1,000pt마다 약 99pt만 더 가게 반영하므로, 끝까지 올린 시트를 살짝 튕겨서는 중간 단계를 건너뛰지 않는다. 숨길 수 있으면 가장 낮은 단계의 절반보다 아래에서 숨긴다. |
| 손잡이 탭 | 위로 한 단계 간다. 맨 위에서는 아래로 한 단계 간다. |
| VoiceOver | 손잡이를 위아래로 쓸어 한 단계씩 바꾼다. 문구는 `Resources/Localizable.xcstrings`(영어, 한국어, 일본어)에 있다. |
| 겹친 시트 | 위 시트를 끄는 동안 아래 시트도 같은 거리만큼 같이 움직인다. 세 장 이상 겹쳐도 맨 아래 시트까지 같이 움직이고, 손을 뗀 뒤에 따라 내려가는 잔상이 생기지 않는다. |
| 애니메이션 | 높이 단계가 바뀔 때만 건다. 화면이 다시 그려진다고 시트에 애니메이션이 걸리지 않는다. |
| 가로 길이 | 계산하지 않고 시트를 붙인 뷰의 너비를 그대로 쓴다. |
| safe area | 내용은 safe area 안에 두고, 배경만 탭바와 홈 인디케이터 아래 화면 끝까지 깐다. 시트를 붙인 뷰가 safe area를 무시하면(지도 화면) 내용도 화면 끝까지 내려가므로, 목록 아래 여백을 내용 쪽에서 넣는다. |
| 배치 | 시트는 늘 가장 큰 높이(`.large`)로 배치하고, 보일 높이만큼만 화면에 올라오도록 아래로 내려(`offset`) 그린다. 화면 밖으로 나간 아래쪽 높이는 내용의 아래 safe area(`safeAreaPadding(.bottom:)`)로 넘겨서, 스크롤 끝이 보이는 영역 안에 온다. 이 값은 시트가 멈춘 뒤(0.6초) 한 번만 바꾼다(16번). 아래로 내린 부분은 잘라서 그리지도 터치를 받지도 않는다. |
| 키보드 | 키보드가 올라와도 시트를 밀어 올리지 않는다. |

끄는 동안에는 시트 안에서만 내리는 거리(`offset`)를 바꾸고, 손을 뗄 때 한 번만 바인딩을 바꾼다. TCA에 연결해도 action이 프레임마다 가지 않는다. 시트 크기는 끄는 동안 바뀌지 않아서, 시트 안 목록과 셀을 다시 배치하지 않는다. 프레임마다 바뀌는 보이는 높이는 바인딩과 따로 `onBottomSheetGeometryChange(_:)`로만 알린다.

시트 안에 아래쪽에 붙는 내용(예: 하단 고정 버튼)을 두려면 아래 safe area를 따르게 둔다. safe area를 무시하면 화면 밖으로 나간 아래쪽에 그려져 보이지 않는다.

## 시스템 시트와 다른 점

- 모달이 아니다. 시트를 붙인 뷰 위에 떠 있고, 시트 밖의 화면은 계속 만질 수 있다.
- 탭바 아래에 깔린다. 시스템 `.sheet`는 탭바까지 덮는다.
- 높이 비율은 창이 아니라 시트를 붙인 뷰를 기준으로 계산한다.
- 시트 내용 안에 붙이는 `presentationDetents` 같은 설정 대신, 높이 단계를 `bottomSheet(...)` 인자로 받는다. 시트 하나의 설정이 한 곳에 모인다.

## SheetKit을 고칠 때 지킬 것

다른 탭과 다른 앱에서도 쓸 수 있도록 아래를 지킨다.

1. SwiftUI 말고는 의존하지 않는다.
2. 보이기와 높이 같은 상태는 `Binding`으로만 받는다. 드래그 이벤트처럼 시트를 움직이는 클로저를 공개 API에 두지 않는다. 바깥에 알리는 클로저는 시트 높이를 읽기만 하는 `onBottomSheetGeometryChange(_:)` 하나다.
3. 기본 모양은 중립으로 두고, PopPang 모양은 DSKit에서 입힌다.
4. 기능은 modifier를 더하는 방식으로 늘린다. 기존 함수의 인자를 바꾸지 않는다.
5. 탭바 높이나 한국어 문구 같은 앱 전용 가정을 넣지 않는다. 화면에 보이거나 읽히는 문구는 `Localizable.xcstrings`에 둔다.
6. 높이 계산과 멈출 높이 계산은 `BottomSheetLayout`의 순수 함수로 두고 `SheetKitTests`로 검사한다.
7. 시트를 `GeometryReader` 클로저 안에서 그리지 않는다. 지도 화면처럼 상위 뷰가 `GeometryReader` 안에 있으면, 바인딩이 바뀌어도 클로저가 다시 실행되지 않아 시트가 나타나지 않았다. 높이는 배경의 `GeometryReader`로 재서 `@State`에 둔다.
8. 끄는 거리와 진행 중인 끌기는 손잡이 줄, 배경, 지정한 뷰가 함께 쓰도록 시트마다 하나인 `BottomSheetDragController`(`@Observable`, `@State`로 보관)에 둔다. 출발지마다 `@GestureState` 플래그를 두어, 끌기가 `onEnded` 없이 끊기면(알림 센터, 앱 전환) 거리를 0으로 되돌린다.
9. 보일지와 높이는 시트를 그리는 뷰가 자기 `@Binding`으로 body에서 읽는다. `bottomSheet(...)` 안에서 값을 미리 읽어 넘겼더니, 지도 화면처럼 상위 뷰가 `GeometryReader` 안에 있을 때 상태가 바뀌어도 시트가 다시 그려지지 않아 두 번째 시트가 열리지 않았다. 7·9번의 증상은 지도 화면이 창의 safe area를 읽어 생긴 그래프 순환([시트 높이 받기](#시트-높이-받기)) 때문이었을 수 있다. 확인 필요: 순환을 고친 지금 7·9번 없이도 시트가 열리는지.
10. 겹친 시트가 같이 움직이도록, 시트마다 끄는 거리를 `BottomSheetLink`에 적는다. 각 시트는 environment로 받은 위 시트들의 연결 목록에 자기 연결을 더해 아래 시트에 넘기고, 아래 시트는 목록에 있는 거리를 모두 더해 움직인다. 가운데 시트가 자기를 그릴 때 위 시트를 적어 두는 방식은 그리는 순서에 따라 맨 아래 시트가 맨 위 시트를 놓칠 수 있어 쓰지 않는다.
11. 멈출 단계는 `DragGesture`의 `predictedEndTranslation`으로 고르지 않는다. `UIScrollView`처럼 멀리 미끄러지게 예측해서, 끝까지 올린 시트를 살짝 튕겨도 중간 단계를 건너뛰고 숨었다. 손을 뗀 높이와 `velocity`로 `BottomSheetLayout.targetDetent`가 고르고, 속도는 감속률 0.99로 짧게 반영한다.
12. 시트 높이는 `BottomSheetGeometryReporter`가 preference로 알린다. `Animatable`이어서 높이 단계를 옮기는 애니메이션 동안에도 중간 높이를 알리므로, 컨테이너의 `.animation(_:value:)`보다 안쪽에 둔다. 도착 높이만 알리면 받는 쪽 버튼이 애니메이션 없이 도착점으로 튄다. 시트 컨테이너 안에 버튼을 같이 그리는 방식은, 시트를 숨기면 버튼도 같이 숨어 쓰는 쪽이 같은 버튼을 하나 더 둬야 해서 쓰지 않는다.
13. 목록(스크롤뷰, `List`)에는 시트 제스처를 붙이지 않는다. 내용 전체에 끌기를 붙이면 SwiftUI는 그중 목록 위 끌기만 골라 뺄 수 없어, 목록을 스크롤할 때 시트도 같이 움직인다.
14. 밖에서 쓸 것만 `public`으로 두고 `Sources/Public/`에 모은다. `Public/` 파일에는 공개 선언과 `Internal/` 타입에 넘기는 짧은 본문만 두고, 구현은 `Sources/Internal/`에 둔다. `Internal/`에는 `public`을 쓰지 않는다. 쓰는 쪽은 [공개 API](#공개-api) 표나 `Public/` 폴더만 보고 시트를 붙일 수 있어야 한다. 공개 API를 더하거나 바꾸면 그 표와 폴더 그림도 같은 작업에서 고친다.
15. 끄는 동안 시트 크기를 바꾸지 않는다. 시트를 `.large` 높이로 배치하고 `offset`으로만 움직인다. 아래로 내린 부분은 `BottomSheetVisibleShape`로 잘라(그리기는 `clipShape`, 터치는 `contentShape`. `clipShape`만으로는 터치가 잘리지 않는다) 그리지도 터치를 받지도 않게 한다(시트를 붙인 뷰가 아래 safe area를 지키면 그 아래에 그려지기 때문이다). 예전에는 `.frame(height:)`를 매 프레임 바꿔서 시트 안 목록(`LazyVStack`)과 셀이 매 프레임 다시 배치돼 지도 화면 시트를 끌 때 버벅였다(#124).
16. 시트 안 내용의 아래 safe area는 시트가 움직이는 동안 바꾸지 않는다. 움직이는 도중에 바꾸면 내용이 시트와 따로 움직였다(내려놓을 때는 가려질 높이만큼 아래로, 올려놓을 때는 위로 튀었다가 따라왔다). `BottomSheetMetrics.settleDuration`(0.6초) 뒤에 바꾼다. 늘릴 때(시트가 작아질 때)는 애니메이션 없이, 줄일 때(시트가 커질 때)는 애니메이션으로 바꾼다. 목록을 끝까지 내린 상태에서 줄이면 스크롤 위치가 맞춰지는데, 애니메이션이 없으면 그만큼 한 번에 튄다. 기다리는 동안 이 시트나 위에 겹친 시트를 끌기 시작하면 바꾸지 않고, 손을 뗀 뒤 다시 0.6초를 기다린다. "움직이는 중인지"를 `task(id:)`의 키(`BottomSheetInsetRequest`)에 넣어서, 끌기가 시작되면 기다리던 작업이 취소되고 끝나면 새로 시작된다. 상태를 주기적으로 확인(폴링)하지 않는다. 시트가 나타날 때는 기다리지 않고 바로 넘긴다(기다리면 그동안 목록 끝까지 스크롤할 수 없다).
17. 내용에 넘기는 environment 값은 매 프레임 새로 만들지 않는다. 예전에는 끌기 처리를 클로저 묶음(struct)으로 매번 새로 만들어 넘겼더니, SwiftUI가 같은 값인지 비교하지 못해 끄는 동안 시트 안 모든 뷰가 매 프레임 다시 갱신됐다(글자를 다시 계산하는 작업까지). 지금은 시트마다 하나인 `BottomSheetDragController`를 넘긴다.
18. `BottomSheetDragController`는 시트 뷰를 붙잡지 않는다. 끌기를 끝낼 때 쓸 값(높이 계산, 높이 단계, 숨길 수 있는지, 연결, 단계를 바꾸는 함수)은 시트를 그릴 때마다 `configuration`에 값으로 넣는다. 처리 클로저가 시트 뷰를 붙잡게 두면, 시트 뷰가 `@State`로 그 객체를 붙잡아 순환 참조가 생긴다. 시트가 사라질 때 클로저를 비우는 방식은 탭을 옮겼다 돌아왔을 때 다시 채워지지 않아 끌기가 멈춰서 쓰지 않는다.

아직 하지 않은 것:

- iPad와 가로 화면 대응
- 시트가 줄어들 때, 시트 안에 아래쪽에 붙는 내용(하단 고정 버튼 등)은 움직임이 끝나고 0.6초 뒤 여백이 바뀔 때까지 화면 밖에 있다. 지금 앱에는 그런 시트가 없다.
- 시트 안 내용이 늘 최대 높이로 배치돼, 화면 밖 아래쪽 셀도 만들어지고 VoiceOver가 닿을 수 있다. 확인 필요: 실기기 VoiceOver
- 다른 앱에서 쓰게 되면 SPM 패키지로 떼어 낸다. 의존성이 없으므로 `Package.swift`를 쓰고 폴더를 옮기면 된다.

## 검증

| 확인할 것 | 방법 |
| --- | --- |
| 높이·멈출 높이 계산, 끌기를 받을 곳 판단 | `xcodebuild test -workspace PopPang.xcworkspace -scheme SheetKit -destination 'id=<시뮬레이터 UDID>'`. CI는 `sheetkit-test` job에서 돌린다. |
| 끌기, 손잡이 탭, 숨기기, 시트 두 장, 키보드, 시트 밖 터치, 시트 높이 받기 | `SheetKitDemo` 실행. 가짜 지도와 내 위치 버튼을 누르면 횟수가 올라가 터치가 닿는지 볼 수 있다. 시트 두 장을 띄우고 위 시트를 끄는 동안 뒤 시트가 보이지 않으면 같이 움직이는 것이다. 내 위치 버튼은 시트를 따라 움직이고, 목록 시트를 끝까지 올리면 숨고, 시트를 숨기면 바닥으로 내려간다. 목록 위에서 끌면 목록만 스크롤되고, 머리 줄과 정렬 옵션을 끌면 시트가 움직인다. |
| PopPang 모양과 탭바 | DSKit 데모(`DSKit` 스킴의 `DSKitDemo`)의 팝팡지도 탭에서 시스템 탭바와 기존 탭바를 바꿔 본다. |
| 지도 화면 | 앱 지도 탭에서 목록 시트와 지역·정렬·미리보기 시트를 열고 닫는다. 내 위치 버튼이 시트를 따라 움직이고, 끝까지 올리면 숨고, 시트를 숨기면 목록 보기 버튼 오른쪽으로 가는지 본다. 숨기고 다시 띄울 때 버튼이 두 개 보이거나 잠시 사라지지 않아야 한다. 목록 위 끌기는 목록만 스크롤하고, 가까운순 줄과 각 시트의 제목 줄을 끌면 시트가 움직이는지 본다. |

## 관련 문서

- [아키텍처](architecture.md)
- [모듈 구조](modules.md)
- [디자인 시스템](design-system.md)
- [TCA Feature 작성 규칙](tca-feature.md)
