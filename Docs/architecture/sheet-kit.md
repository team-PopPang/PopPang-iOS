# SheetKit

이 문서는 SheetKit으로 화면 위에 하단 시트를 붙이는 기준이다. 시트를 새로 붙이거나 SheetKit을 고치기 전에 읽는다.

## 목차

- [개요](#개요)
- [연결 방법](#연결-방법)
- [기본 사용](#기본-사용)
- [내용이 바뀌는 시트](#내용이-바뀌는-시트)
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
| 쓰는 곳 | `MapFeatureView`의 팝업 목록 시트와 지역·정렬·미리보기 시트 |

지도 화면은 서드파티 라이브러리 BottomSheet를 쓰다가 SheetKit으로 바꿨다(이슈 #110). BottomSheet는 숨김과 높이를 한 enum에 섞어 쓰고, 화면이 다시 그려질 때마다 시트 전체에 애니메이션을 걸었다. SheetKit은 이 두 가지를 하지 않는다.

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
| 끌기 | 손잡이가 있는 줄 전체(높이 20pt)를 끌 수 있다. 시트 안의 목록을 끌면 목록만 스크롤된다. |
| 멈출 높이 | 손을 뗀 위치에 속도를 반영한 예상 높이에서 가장 가까운 단계에 멈춘다. 숨길 수 있으면 가장 낮은 단계의 절반보다 아래에서 숨긴다. |
| 손잡이 탭 | 위로 한 단계 간다. 맨 위에서는 아래로 한 단계 간다. |
| VoiceOver | 손잡이를 위아래로 쓸어 한 단계씩 바꾼다. 문구는 `Resources/Localizable.xcstrings`(영어, 한국어)에 있다. |
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
8. 끄는 거리는 `@GestureState`로 둔다. 끌기가 취소돼도(알림 센터, 앱 전환) 0으로 돌아간다.

아직 하지 않은 것:

- 시트 안의 목록을 끌어 시트까지 움직이는 동작(애플 지도 방식). 넣게 되면 시스템 `presentationContentInteraction`처럼 modifier 하나로 켜게 만든다.
- iPad와 가로 화면 대응
- 다른 앱에서 쓰게 되면 SPM 패키지로 떼어 낸다. 의존성이 없으므로 `Package.swift`를 쓰고 폴더를 옮기면 된다.

## 검증

| 확인할 것 | 방법 |
| --- | --- |
| 높이·멈출 높이 계산 | `xcodebuild test -workspace PopPang.xcworkspace -scheme SheetKit -destination 'id=<시뮬레이터 UDID>'`. CI는 `sheetkit-test` job에서 돌린다. |
| 끌기, 손잡이 탭, 숨기기, 시트 두 장, 키보드, 시트 밖 터치 | `SheetKitDemo` 실행. 가짜 지도를 누르면 횟수가 올라가 터치가 통과하는지 볼 수 있다. |
| PopPang 모양과 탭바 | DSKit 데모(`DSKit` 스킴의 `DSKitDemo`)의 팝팡지도 탭에서 시스템 탭바와 기존 탭바를 바꿔 본다. |
| 지도 화면 | 앱 지도 탭에서 목록 시트와 지역·정렬·미리보기 시트를 열고 닫는다. |

## 관련 문서

- [아키텍처](architecture.md)
- [모듈 구조](modules.md)
- [디자인 시스템](design-system.md)
- [TCA Feature 작성 규칙](tca-feature.md)
