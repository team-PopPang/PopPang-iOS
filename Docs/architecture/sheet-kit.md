# SheetKit

이 문서는 SheetKit으로 화면 위에 하단 시트를 붙이는 기준이다. 시트를 새로 붙이거나 SheetKit을 고치기 전에 읽는다.

## 목차

- [개요](#개요)
- [공개 API](#공개-api)
- [연결 방법](#연결-방법)
- [기본 사용](#기본-사용)
- [내용이 바뀌는 시트](#내용이-바뀌는-시트)
- [시트에 붙는 뷰](#시트에-붙는-뷰)
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
| 쓰는 곳 | `MapFeatureView`의 팝업 목록 시트(내 위치 버튼 포함)와 지역·정렬·미리보기 시트 |

지도 화면은 서드파티 라이브러리 BottomSheet를 쓰다가 SheetKit으로 바꿨다(이슈 #110). BottomSheet는 숨김과 높이를 한 enum에 섞어 쓰고, 화면이 다시 그려질 때마다 시트 전체에 애니메이션을 걸었다. SheetKit은 이 두 가지를 하지 않는다.

## 공개 API

SheetKit 밖에서 쓰는 것은 아래뿐이다. 높이 계산, 끌기 처리, 겹친 시트 연결 같은 나머지 타입은 모두 `internal`이라 SheetKit 밖에서는 보이지 않는다. 쓰는 쪽은 이 표만 알면 된다.

| 분류 | API | 하는 일 | 설명 |
| --- | --- | --- | --- |
| 시트 붙이기 | `bottomSheet(detent:detents:content:)` | 높이 바인딩이 `nil`이면 숨는 시트를 붙인다. 가장 낮은 단계보다 아래로 끌면 `nil`이 된다. | [기본 사용](#기본-사용) |
| 시트 붙이기 | `bottomSheet(detent:detents:content:accessory:)` | 위와 같고, 시트 위쪽 끝에 붙어 같이 움직이는 뷰(내 위치 버튼 등)를 함께 그린다. | [시트에 붙는 뷰](#시트에-붙는-뷰) |
| 시트 붙이기 | `bottomSheet(item:detent:detents:content:)` | `item`이 있을 때만 보이는 시트를 붙인다. 끌어서는 숨지 않는다. | [내용이 바뀌는 시트](#내용이-바뀌는-시트) |
| 높이 단계 | `BottomSheetDetent`(`.medium`, `.large`, `.fraction(_:)`, `.height(_:)`) | 시트가 멈출 높이 | [높이 단계](#높이-단계) |
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

## 시트에 붙는 뷰

지도의 내 위치 버튼처럼 시트 위쪽 끝에 붙어 시트와 같이 움직일 뷰는 `accessory`로 넘긴다.

```swift
Map()
    .bottomSheet(detent: $detent) {
        PlaceList()
    } accessory: {
        LocationButton()
            .frame(maxWidth: .infinity, alignment: .trailing)
            .padding(.trailing, 20)
            .padding(.bottom, 12)
    }
```

- 액세서리는 시트 바로 위에 놓이고, 끄는 동안에도 시트와 같은 프레임에 움직인다. 위에 겹친 시트를 끌 때도 같이 움직인다.
- 가장 높은 단계 바로 아래 단계에서 가장 높은 단계로 갈수록 흐려지고, 가장 높은 단계에서는 숨는다.
- 시트를 숨기면 같이 숨는다. 그때 보일 뷰는 쓰는 쪽에서 따로 둔다. 지도 화면은 목록 시트를 숨기면 내 위치 버튼을 목록 보기 버튼 오른쪽에 둔다.
- 가로 위치와 시트와의 간격은 액세서리 쪽에서 정한다.
- 지금은 `bottomSheet(detent:)`에만 있다. `bottomSheet(item:detent:)`에 필요해지면 같은 모양으로 더한다.

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
- 목록이 아니고 시트에 다 들어가는 내용은 스크롤뷰로 감싸지 않고 내용 전체에 붙인다. 지도 화면의 정렬·미리보기 시트가 이렇게 해서 어디를 끌어도 시트가 움직인다.
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
| VoiceOver | 손잡이를 위아래로 쓸어 한 단계씩 바꾼다. 문구는 `Resources/Localizable.xcstrings`(영어, 한국어)에 있다. |
| 겹친 시트 | 위 시트를 끄는 동안 아래 시트도 같은 거리만큼 같이 움직인다. 세 장 이상 겹쳐도 맨 아래 시트까지 같이 움직이고, 손을 뗀 뒤에 따라 내려가는 잔상이 생기지 않는다. |
| 애니메이션 | 높이 단계가 바뀔 때만 건다. 화면이 다시 그려진다고 시트에 애니메이션이 걸리지 않는다. |
| 가로 길이 | 계산하지 않고 시트를 붙인 뷰의 너비를 그대로 쓴다. |
| safe area | 내용은 safe area 안에 두고, 배경만 탭바와 홈 인디케이터 아래 화면 끝까지 깐다. 시트를 붙인 뷰가 safe area를 무시하면(지도 화면) 내용도 화면 끝까지 내려가므로, 목록 아래 여백을 내용 쪽에서 넣는다. |
| 키보드 | 키보드가 올라와도 시트를 밀어 올리지 않는다. |

끄는 동안에는 시트 안에서만 높이를 바꾸고, 손을 뗄 때 한 번만 바인딩을 바꾼다. TCA에 연결해도 action이 프레임마다 가지 않는다.

## 시스템 시트와 다른 점

- 모달이 아니다. 시트를 붙인 뷰 위에 떠 있고, 시트 밖의 화면은 계속 만질 수 있다.
- 탭바 아래에 깔린다. 시스템 `.sheet`는 탭바까지 덮는다.
- 높이 비율은 창이 아니라 시트를 붙인 뷰를 기준으로 계산한다.
- 시트 내용 안에 붙이는 `presentationDetents` 같은 설정 대신, 높이 단계를 `bottomSheet(...)` 인자로 받는다. 시트 하나의 설정이 한 곳에 모인다.

## SheetKit을 고칠 때 지킬 것

다른 탭과 다른 앱에서도 쓸 수 있도록 아래를 지킨다.

1. SwiftUI 말고는 의존하지 않는다.
2. 보이기와 높이 같은 상태는 `Binding`으로만 받는다. 드래그 이벤트 같은 클로저를 공개 API에 두지 않는다.
3. 기본 모양은 중립으로 두고, PopPang 모양은 DSKit에서 입힌다.
4. 기능은 modifier를 더하는 방식으로 늘린다. 기존 함수의 인자를 바꾸지 않는다.
5. 탭바 높이나 한국어 문구 같은 앱 전용 가정을 넣지 않는다. 화면에 보이거나 읽히는 문구는 `Localizable.xcstrings`에 둔다.
6. 높이 계산과 멈출 높이 계산은 `BottomSheetLayout`의 순수 함수로 두고 `SheetKitTests`로 검사한다.
7. 시트를 `GeometryReader` 클로저 안에서 그리지 않는다. 지도 화면처럼 상위 뷰가 `GeometryReader` 안에 있으면, 바인딩이 바뀌어도 클로저가 다시 실행되지 않아 시트가 나타나지 않았다. 높이는 배경의 `GeometryReader`로 재서 `@State`에 둔다.
8. 끄는 거리는 손잡이 줄, 배경, 지정한 뷰가 함께 쓰도록 `@State`에 둔다. 출발지마다 `@GestureState` 플래그를 두어, 끌기가 `onEnded` 없이 끊기면(알림 센터, 앱 전환) 거리를 0으로 되돌린다.
9. 보일지와 높이는 시트를 그리는 뷰가 자기 `@Binding`으로 body에서 읽는다. `bottomSheet(...)` 안에서 값을 미리 읽어 넘겼더니, 지도 화면처럼 상위 뷰가 `GeometryReader` 안에 있을 때 상태가 바뀌어도 시트가 다시 그려지지 않아 두 번째 시트가 열리지 않았다.
10. 겹친 시트가 같이 움직이도록, 시트마다 끄는 거리를 `BottomSheetLink`에 적는다. 각 시트는 environment로 받은 위 시트들의 연결 목록에 자기 연결을 더해 아래 시트에 넘기고, 아래 시트는 목록에 있는 거리를 모두 더해 움직인다. 가운데 시트가 자기를 그릴 때 위 시트를 적어 두는 방식은 그리는 순서에 따라 맨 아래 시트가 맨 위 시트를 놓칠 수 있어 쓰지 않는다.
11. 멈출 단계는 `DragGesture`의 `predictedEndTranslation`으로 고르지 않는다. `UIScrollView`처럼 멀리 미끄러지게 예측해서, 끝까지 올린 시트를 살짝 튕겨도 중간 단계를 건너뛰고 숨었다. 손을 뗀 높이와 `velocity`로 `BottomSheetLayout.targetDetent`가 고르고, 속도는 감속률 0.99로 짧게 반영한다.
12. 시트에 붙는 뷰는 시트 컨테이너 안에서 시트와 같은 높이 값으로 그린다. 시트 위치를 매 프레임 바깥 화면에 알려 그 화면이 버튼을 옮기게 하면, 지도처럼 무거운 화면 전체가 프레임마다 다시 그려진다.
13. 목록(스크롤뷰, `List`)에는 시트 제스처를 붙이지 않는다. 내용 전체에 끌기를 붙이면 SwiftUI는 그중 목록 위 끌기만 골라 뺄 수 없어, 목록을 스크롤할 때 시트도 같이 움직인다.
14. 밖에서 쓸 것만 `public`으로 두고 나머지 타입은 `internal`로 둔다. 쓰는 쪽은 [공개 API](#공개-api) 표만 보고 시트를 붙일 수 있어야 한다. 공개 API를 더하거나 바꾸면 그 표도 같은 작업에서 고친다.

아직 하지 않은 것:

- iPad와 가로 화면 대응
- 다른 앱에서 쓰게 되면 SPM 패키지로 떼어 낸다. 의존성이 없으므로 `Package.swift`를 쓰고 폴더를 옮기면 된다.

## 검증

| 확인할 것 | 방법 |
| --- | --- |
| 높이·멈출 높이 계산, 끌기를 받을 곳 판단 | `xcodebuild test -workspace PopPang.xcworkspace -scheme SheetKit -destination 'id=<시뮬레이터 UDID>'`. CI는 `sheetkit-test` job에서 돌린다. |
| 끌기, 손잡이 탭, 숨기기, 시트 두 장, 키보드, 시트 밖 터치, 시트에 붙는 뷰 | `SheetKitDemo` 실행. 가짜 지도와 내 위치 버튼을 누르면 횟수가 올라가 터치가 닿는지 볼 수 있다. 시트 두 장을 띄우고 위 시트를 끄는 동안 뒤 시트가 보이지 않으면 같이 움직이는 것이다. 목록 시트를 끝까지 올리면 내 위치 버튼이 숨는다. 목록 위에서 끌면 목록만 스크롤되고, 머리 줄과 정렬 옵션을 끌면 시트가 움직인다. |
| PopPang 모양과 탭바 | DSKit 데모(`DSKit` 스킴의 `DSKitDemo`)의 팝팡지도 탭에서 시스템 탭바와 기존 탭바를 바꿔 본다. |
| 지도 화면 | 앱 지도 탭에서 목록 시트와 지역·정렬·미리보기 시트를 열고 닫는다. 내 위치 버튼이 시트를 따라 움직이고, 끝까지 올리면 숨고, 시트를 숨기면 목록 보기 버튼 오른쪽으로 가는지 본다. 목록 위 끌기는 목록만 스크롤하고, 가까운순 줄·제목 줄·정렬과 미리보기 내용을 끌면 시트가 움직이는지 본다. |

## 관련 문서

- [아키텍처](architecture.md)
- [모듈 구조](modules.md)
- [디자인 시스템](design-system.md)
- [TCA Feature 작성 규칙](tca-feature.md)
