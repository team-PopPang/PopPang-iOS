# PopPang 디자인 시스템

이 문서는 DSKit의 토큰과 버튼 스타일로 화면의 색·글자·여백·모서리·버튼 모양을 맞추는 기준이다. 화면 코드를 새로 쓰거나 고칠 때 읽는다.

## 목차

- [구성](#구성)
- [색](#색)
- [텍스트 스타일](#텍스트-스타일)
- [여백과 모서리](#여백과-모서리)
- [버튼 스타일](#버튼-스타일)
- [화면 코드 규칙](#화면-코드-규칙)
- [기존 화면 옮기기](#기존-화면-옮기기)

## 구성

| 층 | 내용 | 위치 |
| --- | --- | --- |
| 토큰 | 색(`PPColor`), 텍스트 스타일(`PPTextStyle`), 여백(`PPSpacing`), 모서리(`PPRadius`) | `Projects/Shared/DSKit/Sources/Token/` |
| 스타일 | 버튼 모양(`PPButtonStyle`), 눌림 효과(`PressableButtonStyle`) | `Projects/Shared/DSKit/Sources/Component/Button/` |
| 구성 요소 | `MainOrangeButton`, `SocialLoginButton`, 텍스트필드 등 | `Projects/Shared/DSKit/Sources/Component/` |
| 하단 시트 모양 | SheetKit 시트에 PopPang 모양(흰 배경, 위쪽 모서리 30)을 입히는 `ppBottomSheetStyle()` | `Projects/Shared/DSKit/Sources/Component/Sheet/` |

토큰과 버튼 스타일은 DSKit 데모(`DSKit` 스킴의 `DSKitDemo`) 카탈로그 화면에서 확인한다.

Figma 같은 디자인 원본이 없다. 그래서 토큰의 역할과 단계는 2026-10-09 기준 화면 코드에서 많이 쓰는 값으로 정했다.

## 색

색은 역할 이름(`PPColor`)으로 고른다. 각 토큰은 기존 팔레트(`UIConstants.swift`의 `Color.mainOrange` 등)를 가리킨다. UIKit에서는 `PPColor.brand.uiColor`처럼 쓴다.

| 토큰 | 팔레트 | 값 | 쓰는 곳 |
| --- | --- | --- | --- |
| `brand` | `mainOrange` | #FF7A00 | 주요 버튼 배경, 강조 글자·아이콘 |
| `brandSubtle` | `subOrange2` | #FFF6ED | 브랜드 색을 옅게 깐 배경 |
| `textPrimary` | `mainBlack` | #333333 | 본문 글자 |
| `textStrong` | `subBlack` | #000000 | 가장 진한 글자 |
| `textSecondary` | `mainGray` | #777777 | 보조 설명 글자 |
| `textTertiary` | `mainGray2` | #AAAAAA | 안내·비활성 글자 |
| `textOnBrand` | `mainWhite` | #F1F1F1 | 브랜드 색 배경 위의 글자 |
| `background` | `subWhite` | #FFFFFF | 기본 화면 배경 |
| `backgroundSecondary` | `mainGray4` | #F8F8F8 | 구역을 나누는 옅은 회색 배경 |
| `border` | `mainGray3` | #CCCCCC | 입력창·카드 테두리 |
| `divider` | `mainGray5` | #EEEEEE | 구분선 |
| `error` | `mainRed` | #DD0000 | 오류 안내 |
| `success` | `mainGreen` | #006813 | 성공 안내 |

- `subWhite2`, `bestPostTitle`, `bestPostAddress`는 각각 `mainGray3`, `subWhite`, `mainGray5`와 값이 같다. 그래서 새 값을 따로 정의하지 않고 그 색을 가리킨다.
- 표에 없는 팔레트 색(`kakao`, `apple` 등)은 해당 구성 요소 안에서만 쓴다.

## 텍스트 스타일

`PPTextStyle`은 글자 크기·행간·자간을 정한다. 굵기는 스타일의 기본값을 쓰고, 다르게 써야 하면 `weight:`로 바꾼다.

```swift
Text("오픈 예정 팝업", bundle: .module)
    .ppTextStyle(.title3)

Text(popup.roadAddress)
    .ppTextStyle(.body4, weight: .medium)
```

| 스타일 | 크기 | 기본 굵기 |
| --- | --- | --- |
| `display` | 26pt | extraBold |
| `title1` | 20pt | bold |
| `title2` | 18pt | bold |
| `title3` | 17pt | bold |
| `body1` | 15pt | medium |
| `body2` | 14pt | medium |
| `body3` | 13pt | regular |
| `body4` | 12pt | regular |
| `caption1` | 11pt | regular |
| `caption2` | 10pt | light |
| `caption3` | 9pt | regular |

- 행간은 글자 크기의 1.4배, 자간은 글자 크기의 0.02배다. `ppStyleFont`의 기본값과 같다.
- UIKit에서는 `PPTextStyle.body1.uiFont()`로 글꼴을 얻는다.
- SCDream에는 한자와 장음 기호(`ー`)가 없다. `UIFont.scdream`이 빠진 글자를 화면 언어에 맞는 시스템 고딕(일본어는 히라기노 고딕, 한국어는 Apple SD Gothic Neo)으로 채운다. ([다국어 문구](../development/localization.md#글꼴))
- 예전 글꼴 토큰(`Font.largeTitle`, `title1`~`title3`, `caption1`~`caption3`, `bottomBtn`, `homeTitle`)은 쓰는 곳이 없어 지웠다. 이 가운데 `largeTitle`, `title2`, `title3`, `caption2`는 SwiftUI 기본 글꼴 이름과 겹쳤다.

## 여백과 모서리

| 토큰 | 값 | 쓰는 곳 |
| --- | --- | --- |
| `PPSpacing.s4`~`PPSpacing.s24` | 4, 5, 8, 10, 12, 15, 20, 24 | 여백과 stack 간격 |
| `PPSpacing.screenHorizontal` | 15 | 화면 좌우 여백. `CGFloat.contentPadding`과 같다. |
| `PPRadius.small` | 5 | 버튼·입력창. `CGFloat.cornerRadius`와 같다. |
| `PPRadius.medium` | 10 | 카드·이미지 |
| `PPRadius.large` | 16 | 시트·큰 카드 |

- 알약 모양은 `Capsule()`을 쓴다.
- SheetKit 하단 시트의 모서리는 지도 시트에서 쓰던 30이다. `PPRadius`에 없는 값이라 `ppBottomSheetStyle()` 안에 둔다.
- 목록에 없는 값이 필요하면 화면에 숫자를 쓰지 않고 먼저 토큰을 추가한다.

## 버튼 스타일

```swift
Button(String(localized: "다음", bundle: .module)) { store.send(.nextTapped) }
    .buttonStyle(.ppPrimary)
```

| 스타일 | 모양 |
| --- | --- |
| `.ppPrimary` | 브랜드 색 배경. 높이 56pt이고 가로를 채운다. |
| `.ppOutline` | 흰 배경에 브랜드 색 테두리. 높이 56pt이고 가로를 채운다. |
| `.ppText` | 배경 없이 브랜드 색 글자만 있다. 높이 44pt다. |
| `.pp(_:size:fillsWidth:)` | 종류(`primary`, `outline`, `text`), 크기(`large` 56pt, `medium` 44pt, `small` 32pt), 너비를 고른다. |

- `.ppPrimary`, `.ppOutline`은 `MainOrangeButton`의 기본·반전(`isReversed`) 모양과 같다.
- 모든 종류에 `PressableButtonStyle`과 같은 눌림 효과가 들어 있다. 누르면 0.95배로 줄고 불투명도가 0.85가 된다.
- `.disabled(true)`인 버튼은 불투명도 0.4로 그린다.
- 버튼 글자는 한 줄이라 행간·자간을 넣지 않는다.
- 회색 보조 버튼처럼 지금 화면에 기준 모양이 없는 종류는 넣지 않았다. 필요해지면 이 문서와 함께 추가한다.

## 화면 코드 규칙

- 새로 쓰거나 고치는 화면은 `PPColor`, `ppTextStyle`, `PPSpacing`, `PPRadius`, `PPButtonStyle`을 쓴다.
- 화면 코드에 hex 색, `.scdream(...)`, 여백·모서리 숫자를 직접 쓰지 않는다. DSKit 안의 토큰 정의와 구성 요소 구현은 예외다.
- 누르는 영역은 `onTapGesture` 대신 `Button`으로 만든다. 그래야 VoiceOver가 버튼으로 읽고 눌림 효과도 적용된다.
- 화면 문구는 모듈의 `Resources/Localizable.xcstrings`에 두고 `bundle: .module`로 읽는다. ([다국어 문구](../development/localization.md))
- 기존 이름(`Color.mainOrange`, `ppStyleFont`, `MainOrangeButton` 등)은 그대로 동작한다. 기존 화면을 옮기는 작업은 아래 기준으로 따로 한다.

## 기존 화면 옮기기

- 화면 묶음별로 PR을 나누고, 바꾸기 전후 스크린샷을 PR에 붙인다.
- 글자는 같은 크기의 스타일로 바꾸고, 기존 굵기가 스타일 기본값과 다르면 `weight:`로 유지한다. `.font(.scdream(...))`만 쓰던 곳에 `ppTextStyle`을 적용하면 행간·자간이 생겨 높이가 달라질 수 있다.
- 여백과 모서리는 목록에 있는 값이면 토큰으로 바꾼다. 목록에 없는 값(여백 28·18·16·30, 모서리 6·12·14·15·17·18 등)은 가까운 토큰으로 바꾸거나 토큰을 추가할지 정한다.
- 눌림 효과가 없는 `Button`에는 `PPButtonStyle`이나 `PressableButtonStyle`을 적용한다.

### 기준값

2026-10-09 기준 화면 코드에서 센 값이다. 기존 화면을 옮기는 작업이 얼마나 진행됐는지 이 값과 비교한다. 굵기·크기 조합은 DSKit까지 포함해 셌고, 나머지는 `Projects/Features`와 `Projects/App`에서 데모·테스트를 빼고 셌다.

| 항목 | 개수 |
| --- | --- |
| `.scdream(...)` 직접 지정 | 153곳 |
| 굵기·크기 조합 | 34종 |
| 숫자로 쓴 모서리 | 18곳(14종) |
| 숫자로 쓴 padding 값 | 30종 |
| `Button` 직접 생성 | 63곳(눌림 효과가 있는 곳 11곳) |
| `onTapGesture` | 9곳 |

## 관련 문서

- [아키텍처](architecture.md)
- [모듈 구조](modules.md)
- [Swift 스타일](../development/swiftstyle.md)
- [다국어 문구](../development/localization.md)
