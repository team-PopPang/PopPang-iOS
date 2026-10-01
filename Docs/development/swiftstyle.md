# PopPang Swift 스타일

이 문서는 PopPang Swift 코드의 작성 규칙이다. `Projects/` 아래 코드에서 가장 많이 쓰는 관례를 기준으로 정리했고, 섞여 있는 부분은 새 코드에서 따를 쪽을 적었다. TCA reducer와 view 구조는 [TCA Feature 작성 규칙](../architecture/tca-feature.md)을 본다.

## 목차

- [도구](#도구)
- [파일 헤더](#파일-헤더)
- [import](#import)
- [포맷](#포맷)
- [이름](#이름)
- [접근 제어와 타입](#접근-제어와-타입)
- [switch와 guard](#switch와-guard)
- [클로저와 메모리](#클로저와-메모리)
- [동시성](#동시성)
- [주석](#주석)
- [로그](#로그)

## 도구

- SwiftLint, SwiftFormat, swift-format, `.editorconfig` 설정이 없다. 포맷은 이 문서와 주변 코드를 기준으로 맞춘다.
- 에이전트는 승인 없이 포매터를 실행하지 않는다.
- PR 자동 리뷰는 CodeRabbit(`.coderabbit.yaml`)이 한다. `path_instructions`가 지금은 없는 `PopPang/Sources/**` 경로를 가리키고 있다(`확인 필요`).

## 파일 헤더

새 파일에는 파일 헤더 주석을 넣지 않는다. 파일은 `import`로 시작한다. Tuist 템플릿도 헤더를 만들지 않는다.

일부 파일에 Xcode 기본 헤더(`//  FileName.swift`, `//  Module`, `//  Created by ... on M/D/YY.`)가 남아 있다. 그 파일을 고칠 때 헤더의 파일 이름이 실제와 다르면 헤더를 고치거나 지운다.

## import

한 블록에 알파벳순(대소문자 무시)으로 적고 빈 줄로 나누지 않는다. Apple 프레임워크, TCA, 외부 SDK, 내부 모듈을 따로 묶지 않는다.

```swift
// Preferred
import ComposableArchitecture
import Core
import Domain
import DSKit
import Kingfisher
import SwiftUI

// Avoid
import SwiftUI

import ComposableArchitecture
import Domain
import Core
```

- 테스트 파일은 정렬한 블록 뒤에 `@testable import <Module>`을 마지막에 둔다.
- 다른 모듈에 같은 이름의 타입이 있으면 `import struct HomeFeatureV2.HomeFeatureView`처럼 타입 단위로 import한다.
- SDK는 실제 모듈 이름으로 import한다. `ThirdParty`는 SDK를 다시 노출하지 않는다.

## 포맷

### 들여쓰기와 줄 바꿈

- 들여쓰기는 공백 4칸이다. 줄 끝 공백을 남기지 않는다.
- 파라미터가 3개 이상인 선언과 호출은 파라미터마다 줄을 바꾸고, 닫는 `)`를 따로 한 줄에 둔다. 2개 이하면 보통 한 줄에 쓴다.

```swift
public func getPersonalFilteredPopupList(
    userUuid: String,
    region: String,
    district: String,
    homeSortStandard: String
) async throws -> [Popup]
```

- 삼항 연산자가 길면 `?`와 `:` 앞에서 줄을 바꾼다. `&&` 연결은 줄 앞에 연산자를 둔다.

```swift
let regions = state.regions.isEmpty
    ? try await calendarFeatureClient.getRegionList().sortedByCalendarPriority()
    : state.regions

lhs.user == rhs.user
&& lhs.selectedTab == rhs.selectedTab
```

- 여러 줄 배열·딕셔너리 리터럴에는 마지막 요소 뒤에 쉼표를 둔다. 함수 인자 목록에는 두지 않는다.
- 줄이 길어지면 파라미터 단위로 나눈다.

### 클로저 문법

- trailing closure를 쓴다. 클로저가 여러 개여도 trailing closure 문법을 쓴다.

```swift
Button {
    store.send(.alertTapped)
} label: {
    Text("알림")
}

Store(initialState: AppFeature.State()) {
    AppFeature(...)
} withDependencies: {
    $0.localSessionClient = localSessionClient
}
```

- 콜백이 여러 개인 하위 view는 `onSearch:`, `onAlert:`처럼 라벨을 붙여 전달해도 된다.

### self

- 이니셜라이저의 `self.x = x`처럼 꼭 필요한 곳에만 `self`를 쓴다. 나머지는 생략한다.

## 이름

### 타입과 파일

| 대상 | 형식 | 예 |
| --- | --- | --- |
| reducer / view | `<Name>Feature` / `<Name>FeatureView` | `CalendarFeature`, `CalendarFeatureView` |
| navigation 래퍼 | `<Name>DestinationFeature` / `<Name>DestinationView` | `PopupDetailDestinationFeature` |
| client | `<Name>FeatureClient`, key `<name>FeatureClient` | `calendarFeatureClient` |
| Usecase | `<Name>UsecaseProtocol` / `<Name>UsecaseImpl` | `PopupUsecaseImpl`. `UseCase`로 쓰지 않는다. |
| Repository | `<Name>RepositoryProtocol` / `<Name>RepositoryImpl` | `PopupRepositoryImpl` |
| DTO | `<Name>DTO`, `<Name>RequestDTO` | `PopupDTO` |
| Entity | 접미사 없는 명사 | `Popup`, `User` |
| 변환 파일 | `<Entity>+DataMapping.swift`, `toEntity()` / `toDTO()` | `User+DataMapping.swift` |
| Moya target | `<Name>API` | `PopupAPI` |
| 로컬 저장소 | `<Name>Storage` | `RecentSearchStorage` |
| SwiftUI 셀 / UIKit 셀 모델 | `<Name>Cell` / `<Name>Component` | `GridPopupCell` |

`Projects/App/Sources/AppCore`의 파일은 읽는 순서를 숫자 접두사로 표시한다(`0. AppSDKInitializer.swift` ~ `8. AppFeature.swift`).

### 값과 약어

- 서버 식별자는 `Uuid`로 쓴다: `userUuid`, `popupUuid`. `UUID`, `Id`로 바꾸지 않는다.
- 서버 응답을 그대로 옮긴 모델은 서버 필드 이름을 따른다: `instaPostId`, `imageUrlList`.
- 앱 안에서만 쓰는 값은 `ID`, `URL`을 대문자로 쓴다: `userID`, `slotID`, `appStoreURL`.
- Bool은 `is`, `has`, `should`로 시작한다.
- enum case는 lowerCamelCase다. raw value는 서버 상수(`case pending = "PENDING"`)나 화면 표시 문자열(`case all = "전체"`)을 쓴다.
- action 이름은 [TCA Feature 작성 규칙](../architecture/tca-feature.md#action)을 따른다.

### 철자가 틀린 기존 이름

`getPersonalUseerRecommendPopupList`, `getRecommandList`, section id `"comming"`은 철자가 틀렸지만 API·public protocol·화면 동작과 연결되어 있다. 호출할 때는 기존 이름을 그대로 쓰고, 이름을 고치는 작업은 별도로 계획한다.

## 접근 제어와 타입

- 모듈 밖에서 쓰는 것은 `public`이다: reducer, `State`, `Action`, view와 init, client, `DependencyValues` key, Domain entity의 프로퍼티와 `public init`.
- App 타깃 안의 타입은 internal로 둔다.
- 내부 helper는 파일 끝 `private extension <Type> { ... }`에 모은다. `fileprivate`은 쓰지 않는다.
- 상속하지 않는 class는 모두 `final`이다.
- 계산 프로퍼티의 `switch`는 `return` 없는 표현식으로 쓴다.

```swift
var title: String {
    switch self {
    case .home:
        "홈"
    case .calendar:
        "캘린더"
    }
}
```

## switch와 guard

- 직접 정의한 enum과 reducer action의 `switch`에는 최상위 `default`를 쓰지 않는다. 튜플 비교나 중첩 helper에서는 써도 된다.
- 조건이 짧은 `guard`는 한 줄로 쓴다.

```swift
guard state.destination == .launch else { return .none }
```

- 조건이 여러 개인 `guard`는 조건마다 줄을 바꾼다.

```swift
guard state.hasStarted,
      state.hasNext,
      !state.isRequesting,
      let cursor = state.nextCursor
else {
    return .none
}
```

## 클로저와 메모리

- class 안의 escaping 클로저는 `[weak self]`로 캡처하고 `self?.`로 접근한다.
- reducer effect는 `self`를 캡처하지 않는다. client와 값을 지역 상수로 꺼내 캡처한다.
- 화면 전환용 escaping closure는 만들지 않는다. ([TCA Navigation](../architecture/tca-navigation.md#closure-구분))

## 동시성

- manifest에 Swift 언어 모드와 strict concurrency 설정이 없다. 코드상 Swift 5 언어 모드로 보인다(`확인 필요`: 생성된 project의 `SWIFT_VERSION`).
- Domain entity, DTO, feature client는 `Sendable`이다.
- Usecase·Repository protocol은 `Sendable`이 아니다. client의 `@Sendable` 클로저에서 캡처할 때는 `private final class <Name>UsecaseBox: @unchecked Sendable`로 감싼다. ([의존성 주입](../architecture/dependency-injection.md))
- `@unchecked Sendable`은 위 Box와 `UserDefaultsStore`, `NetworkProvider`처럼 내부 동기화가 필요 없는 경우에만 쓴다.
- UI와 연결된 객체(`AppDeepLinkHandler`, ADKit slot store)와 테스트 suite는 `@MainActor`로 선언한다.
- 언어 모드나 concurrency 설정을 바꾸는 것은 모듈 설정 변경이므로 계획에 적고 승인을 받는다.

## 주석

- 설명 주석은 한국어로 쓴다.
- `///` 문서 주석은 선언 바로 위에만 쓴다. enum case 뒤에 붙이거나 함수 본문 안에 쓰지 않는다.
- `- Returns: [Popup]`처럼 타입만 반복하는 태그는 쓰지 않는다. 필요한 내용(조건, 실패, 단위)이 있을 때만 `- Parameter`, `- Returns`를 쓴다.
- 문장 어미는 그 파일의 기존 주석에 맞춘다.
- `// MARK: - 제목` 형식으로 쓰고, 파일이 길어 구역이 필요할 때만 쓴다. 설명 문장을 MARK로 쓰지 않는다.

## 로그

`Core`의 `Logger`를 쓴다.

```swift
Logger.d("팝업 목록을 불러왔다: \(popups.count)개")
Logger.w("저장된 세션이 없다")
Logger.e("푸시 토큰 동기화 실패: \(error.localizedDescription)")
```

- `print`를 새로 쓰지 않는다. reducer와 view에 남은 `print`는 정리 대상이다.
- `Logger`는 DEBUG 빌드에만 제한되지 않고 `print`로 출력한다. 토큰, 비밀번호, 개인정보를 로그에 남기지 않는다.
- Firebase 화면 로그 modifier `trackScreen(_:)`(`Projects/App/Sources/AppCore/FirebaseLogger.swift`)는 지금 호출하는 곳이 없다. 화면 로그를 새로 붙이는 것은 분석 정책 변경이므로 따로 결정한다.

## 관련 문서

- [TCA Feature 작성 규칙](../architecture/tca-feature.md)
- [의존성 주입](../architecture/dependency-injection.md)
- [테스트](testing.md)
