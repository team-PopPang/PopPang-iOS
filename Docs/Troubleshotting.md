# Troubleshotting

이 문서는 Tuist + SPM + 모듈러 구조에서 외부 라이브러리 링크 문제가 다시 생겼을 때 확인할 기준이다.

static/dynamic product type 선택 기준은 `Docs/static-dynamic-linking.md`를 먼저 본다.

## 탭바가 숨겨진 상세 화면에서 뒤로가기 시 탭바가 늦게 복귀하는 문제

증상:

- 홈, 캘린더, 지도, 찜, 프로필/알림 등 탭 플로우에서 팝업 셀을 눌러 `PopupDetailFeatureView`로 이동한다.
- 상세 화면에서는 탭바가 없어야 한다.
- 뒤로가기 시 탭바가 즉시 돌아오지 않고 잠깐 텀이 생기거나, 탭바 hide/show 애니메이션이 어색하게 보인다.

원인:

- V0는 `NavigationStack { TabView { ... } }` 구조였다.
- 따라서 `popupDetail` route는 `TabView` 내부가 아니라 `TabView` 전체 위로 push되었고, 상세 화면에는 애초에 부모 탭바가 존재하지 않았다.
- 모듈러 구조에서는 `TabView { 각 탭별 CoordinatorContainer/NavigationStack }` 형태였고, 팝업 상세가 각 탭 내부 `NavigationStack`에 push되었다.
- 이 상태에서 `PopupDetailFeatureView`가 `.toolbar(.hidden, for: .tabBar)`로 시스템 탭바를 숨기면, pop 시점에 탭바 복구 타이밍이 SwiftUI toolbar 처리에 묶여 텀이 생긴다.

해결:

- 각 탭의 팝업 선택은 탭 내부 route로 직접 push하지 않는다.
- `HomeFeatureView`, `CalendarFeatureView`, `MapFeatureView`, `FavoritesFeatureView`, `AlertFeatureView` 등은 `onSelectPopup` 콜백만 호출한다.
- 각 탭 coordinator는 해당 콜백을 `MainTabCoordinator`로 전달한다.
- `MainTabCoordinatorView`가 `NavigationStack`으로 `TabView`를 감싸고, `MainTabRoute.popupDetail`을 `navigationDestination(item:)` 상위 destination으로 push한다.
- 상위 destination으로 열린 `PopupDetailFeatureView`는 `hidesSystemTabBar: false`로 생성한다. 이 화면은 이미 `TabView` 바깥 destination이라 숨길 탭바가 없다.

주의:

- 탭 내부 route로 상세를 push하는 fallback 경로는 아직 있을 수 있으므로 `PopupDetailFeatureView`의 기본값은 `hidesSystemTabBar: true`로 유지한다.
- V0와 같은 체감을 원하면 사용자 플로우의 팝업 상세 진입점은 가능한 상위 route로 모아야 한다.
- 상위 `NavigationStack`에 typed path 배열을 두고, 탭 내부에도 각기 다른 typed path의 `NavigationStack`을 중첩하면 SwiftUI가 내부 path 비교 중 `AnyNavigationPath.Error.comparisonTypeMismatch`로 크래시할 수 있다. 그래서 상위 팝업 상세 route는 단일 optional item route로 둔다.

## BottomSheet 안의 지도 목록이 데이터 변경을 바로 반영하지 않는 문제

증상:

- 팝팡지도 탭 첫 진입 시 첫 번째 시트에 `검색 결과가 없습니다.`가 표시된다.
- 같은 화면에서 가까운순/최신순 정렬 버튼을 한 번 누르면 갑자기 목록 데이터가 나타난다.
- 서버 요청은 이미 성공했거나 이후 state에는 데이터가 들어왔는데, BottomSheet 내부 목록만 늦게 갱신되는 것처럼 보인다.

원인:

- `BottomSheet` 라이브러리는 `content` closure를 매 렌더링 때 다시 실행하는 구조가 아니라, `mainContent`를 값으로 보관한다.
- 첫 번째 시트에 `popups`, `isLoading` 같은 state 값을 복사해서 넘기면, parent view의 compound state 변경만으로 BottomSheet 내부 content가 기대한 타이밍에 다시 구성되지 않을 수 있다.
- 반면 정렬 버튼을 누르면 local sheet position/type state가 바뀌면서 parent body가 다시 평가되고, 그때 최신 데이터가 BottomSheet content에 반영되어 갑자기 목록이 나타난다.

해결:

- BottomSheet의 content에 state snapshot만 넘기지 않는다.
- 첫 번째 시트가 `MapFeatureCompound`를 직접 받아 내부에서 `compound.state.mapPopups`, `compound.state.isLoading`, `compound.state.didPreload`를 읽게 한다.
- 최초 로드 전에는 빈 배열을 곧바로 `검색 결과가 없습니다.`로 해석하지 않고 `ProgressView`를 보여준다.

예시:

```swift
FirstSheetView(
    compound: compound,
    selectedOption: selectedOptionBinding,
    firstSheetPosition: $firstSheetPosition,
    ...
)
```

```swift
private struct MapListView: View {
    let popups: [Popup]
    let isLoading: Bool
    let didPreload: Bool

    var body: some View {
        if !didPreload || isLoading {
            ProgressView()
        } else if popups.isEmpty {
            Text("검색 결과가 없습니다.")
        } else {
            // list
        }
    }
}
```

주의:

- BottomSheet 안에 들어가는 view는 가능하면 값 snapshot보다 관찰 대상이나 binding을 직접 전달한다.
- 정렬 버튼을 눌렀을 때만 목록이 나타나는 현상은 API 문제가 아니라 BottomSheet content 갱신 문제일 가능성이 높다.
- 다만 API 로그에 500이 같이 보이면 별도 문제다. V0 기준 지도 가까운순은 클라이언트 정렬이 아니라 `mapSortStandard=CLOSEST` 서버 필터링이다.

## 팝팡지도 첫 진입 시 첫 번째 BottomSheet 높이가 고정되는 문제

증상:

- 팝팡지도 탭에 처음 진입하면 첫 번째 시트가 위아래로 움직이지 않는다.
- 팝업 셀을 눌러 두 번째 시트가 한 번 올라온 뒤에는 시트 높이 변경이 다시 동작한다.

원인:

- `sheetTop` 갱신에 맞춰 첫 번째 시트에 `.id(...)`를 주면 검색바 frame 계산 직후 시트 view가 재생성된다.
- 이 재생성 타이밍이 `BottomSheet` 내부 gesture/layout 상태와 겹치면 첫 진입 시 첫 번째 시트 drag가 먹지 않는 것처럼 보일 수 있다.
- V0처럼 두 시트의 position 동기화는 유지하되, 모듈러 화면에서 두 번째 시트를 첫 번째 시트와 같은 modifier 체인에 붙이면 hidden wrapper가 첫 번째 시트 drag에 간섭할 수 있다.

해결:

- 첫 번째 시트는 `sheetTop` 변경 때문에 `.id(...)`로 강제 재생성하지 않는다.
- 두 번째 시트는 첫 번째 시트 modifier 체인에 이어 붙이지 않고, 같은 `ZStack` 안의 별도 overlay sibling으로 분리한다.
- 두 번째 시트 overlay는 항상 트리에 두되, `secondSheetPosition == .hidden`일 때는 `.allowsHitTesting(false)`로 첫 번째 시트 제스처를 막지 않게 한다.
- 첫 번째/두 번째 시트 높이 동기화는 `secondSheetPosition`이 visible 상태일 때만 유지한다.

예시:

```swift
.bottomSheet(
    bottomSheetPosition: $firstSheetPosition,
    switchablePositions: [.absolute(0), .relative(0.5), .absoluteTop(sheetTop)]
) {
    FirstSheetView(...)
}

Color.clear
    .bottomSheet(
        bottomSheetPosition: $secondSheetPosition,
        switchablePositions: [.relative(0.5), .absoluteTop(sheetTop)]
    ) {
        SecondSheetView(...)
    }
    .allowsHitTesting(secondSheetPosition != .hidden)
```

## ThirdParty 링크 원칙

PopPang은 Haruhancut-V2 방식처럼 외부 라이브러리 SPM product를 `ThirdParty` 타깃에 모은다.

- 외부 SDK `.external(...)` 선언은 `Projects/Shared/ThirdParty/Project.swift`에만 둔다.
- `Data`, `Core`, `Feature`, `Coordinator`, `App`, `DSKit`은 외부 SDK를 직접 `.external(...)`로 링크하지 않고 `ThirdParty` 프로젝트 타깃에 의존한다.
- Swift 파일은 `import ThirdParty`로 SDK 사용 사실을 숨기지 않는다.
- 실제 SDK 타입을 쓰는 파일은 `import Moya`, `import Kingfisher`, `import KakaoSDKAuth`, `import GoogleSignIn`처럼 실제 모듈명을 직접 import한다.
- `ThirdParty`는 `@_exported import`로 SDK를 재노출하지 않는다.
- wrapper/adapter는 기본 전략이 아니다. 꼭 필요할 때만 별도 판단한다.

## KakaoSDKCommon duplicate class 경고

증상:

```text
objc[...] Class _TtC14KakaoSDKCommon8KakaoSDK is implemented in both
.../Data.framework/Data
and
.../Coordinator.framework/Coordinator
```

원인:

- `Data`는 `KakaoSDKAuth`, `KakaoSDKUser`를 직접 import한다.
- `PopupDetailFeature`는 `KakaoSDKShare`, `KakaoSDKTemplate`, `KakaoSDKCommon`을 직접 import한다.
- `PopupDetailFeature`는 static feature 산출물로 `Coordinator.framework`에 합쳐진다.
- Kakao SDK product가 기본 static product로 처리되면 `KakaoSDKCommon` 코드가 `Data.framework`와 `Coordinator.framework`에 각각 들어간다.
- 그 결과 같은 Objective-C/Swift 런타임 클래스가 두 프레임워크에서 중복 등록된다.

해결:

- Kakao 관련 `.external(...)`은 `Projects/Shared/ThirdParty/Project.swift`에만 둔다.
- `Data`, `PopupDetailFeature`, `Coordinator` 등은 `ThirdParty` 프로젝트 타깃에 의존한다.
- 소스에서는 기존처럼 `import KakaoSDKAuth`, `import KakaoSDKUser`, `import KakaoSDKShare`를 직접 쓴다.
- `Tuist/Package.swift`에서 실제 사용하는 Kakao product를 `.framework`로 고정한다.

```swift
"KakaoSDKAuth": .framework,
"KakaoSDKCommon": .framework,
"KakaoSDKShare": .framework,
"KakaoSDKTemplate": .framework,
"KakaoSDKUser": .framework,
```

왜 product type override가 필요한가:

- `.external(...)`을 `ThirdParty`에만 모아도, 각 모듈이 SDK를 직접 import하면 Swift auto-link가 동작한다.
- product가 static이면 해당 SDK 코드가 import한 동적 프레임워크 안으로 들어갈 수 있다.
- Kakao는 `Data`와 `Coordinator` 양쪽 import 경로가 있으므로 `KakaoSDKCommon`이 중복 포함된다.
- `.framework`로 고정하면 앱 번들의 `KakaoSDKCommon.framework` 한 곳에서 로드되어 중복 class 경고가 사라진다.

검증:

```sh
rg -n 'external\(name: "(Kakao|GoogleSignIn|Firebase|Moya|NMapsMap|Kingfisher|Compound)' Projects --glob 'Project.swift'
tuist generate
xcodebuild -workspace PopPang.xcworkspace -scheme PopPangApp -destination 'platform=iOS Simulator,name=iPhone 16,OS=18.5' build
```

첫 번째 명령 결과는 `Projects/Shared/ThirdParty/Project.swift`만 나와야 한다.
앱 실행 또는 테스트 로그에서 `Class _TtC14KakaoSDKCommon... is implemented in both` 문구가 나오면 아직 해결되지 않은 상태다.

## GoogleSignIn undefined symbols

증상:

```text
Undefined symbols for architecture arm64:
  "_OBJC_CLASS_$_GTMSessionFetcher"
  "_OBJC_CLASS_$_OIDAuthState"
  "_OBJC_CLASS_$_FBLPromise"
  "_GULAppEnvironmentUtil"
ld: symbol(s) not found for architecture arm64
```

원인:

- `GoogleSignIn`은 `AppAuth`, `AppAuthCore`, `AppCheckCore`, `GTMAppAuth`, `GTMSessionFetcherCore`, `GoogleUtilities` 계열에 의존한다.
- Tuist의 기본 SPM product type은 static framework 기준이다.
- `ThirdParty` 허브에만 `.external(name: "GoogleSignIn")`을 두고 `Data`가 `import GoogleSignIn`을 직접 쓰는 구조에서, `Data.framework` 링크 단계가 GoogleSignIn의 전이 심볼을 충분히 찾지 못했다.
- 그래서 `Data.framework` 링크 단계에서 `AppAuth`, `AppCheck`, `GTM`, `GoogleUtilities`, `Promises` 관련 심볼 누락이 발생했다.

해결:

`Tuist/Package.swift`의 `PackageSettings.productTypes`에서 `GoogleSignIn`과 직접 전이 product를 `.framework`로 고정한다.

현재 필요한 항목:

```swift
"AppAuth": .framework,
"AppAuthCore": .framework,
"AppCheckCore": .framework,
"FBLPromises": .framework,
"GoogleSignIn": .framework,
"GTMAppAuth": .framework,
"GTMSessionFetcherCore": .framework,
"GoogleUtilities-Environment": .framework,
"GoogleUtilities-Logger": .framework,
"GoogleUtilities-UserDefaults": .framework,
"GULEnvironment": .framework,
"GULUserDefaults": .framework,
"third-party-IsAppEncrypted": .framework,
```

각 항목의 소속:

| product | 소속 SPM package | 왜 필요한가 |
| --- | --- | --- |
| `GoogleSignIn` | `https://github.com/google/GoogleSignIn-iOS` | Data의 `GoogleAuthRepositoryImpl`이 직접 import하는 Google 로그인 SDK |
| `AppAuth` | `https://github.com/openid/AppAuth-iOS` | `GoogleSignIn`의 OAuth 인증 전이 의존성 |
| `AppAuthCore` | `https://github.com/openid/AppAuth-iOS` | `GoogleSignIn`, `GTMAppAuth`가 사용하는 AppAuth core 전이 의존성 |
| `AppCheckCore` | `https://github.com/google/app-check` | `GoogleSignIn`의 App Check 전이 의존성 |
| `FBLPromises` | `https://github.com/google/promises` | `AppCheckCore`에서 참조하는 Promise 구현체 |
| `GTMAppAuth` | `https://github.com/google/GTMAppAuth` | `GoogleSignIn`의 GTM OAuth bridge 전이 의존성 |
| `GTMSessionFetcherCore` | `https://github.com/google/gtm-session-fetcher` | `GoogleSignIn`, `GTMAppAuth` 네트워크 전이 의존성 |
| `GULEnvironment` | `https://github.com/google/GoogleUtilities` | `AppCheckCore`가 사용하는 GoogleUtilities product |
| `GULUserDefaults` | `https://github.com/google/GoogleUtilities` | `AppCheckCore`가 사용하는 GoogleUtilities product |
| `GoogleUtilities-Environment` | `https://github.com/google/GoogleUtilities` | Tuist가 생성한 target 이름 기준 override |
| `GoogleUtilities-Logger` | `https://github.com/google/GoogleUtilities` | Tuist가 생성한 target 이름 기준 override |
| `GoogleUtilities-UserDefaults` | `https://github.com/google/GoogleUtilities` | Tuist가 생성한 target 이름 기준 override |
| `third-party-IsAppEncrypted` | `https://github.com/google/GoogleUtilities` | GoogleUtilities 내부 third-party target |

이 설정은 `Data`에 `.external(name: "GoogleSignIn")`을 다시 추가하는 방식보다 낫다. 직접 `.external(...)`을 여러 모듈에 넣으면 Kakao duplicate class 문제와 같은 중복 링크 문제가 재발할 수 있다.

## Kakao 로그인 MustInitAppKey fatal

증상:

```text
KakaoSDKCommon.SdkError.ClientFailed(
  reason: KakaoSDKCommon.ClientFailureReason.MustInitAppKey,
  errorMessage: Optional("initSDK(appKey:) must be initialized.")
)
```

원인:

- V0는 `AppDelegate.application(_:didFinishLaunchingWithOptions:)`에서 `KakaoSDK.initSDK(appKey: Constants.KakaoAPI.key)`를 호출했다.
- 모듈러 SwiftUI App으로 옮기면서 이 앱 시작 초기화가 빠지면, `UserApi.shared.loginWithKakaoTalk` 호출 시점에 Kakao SDK app key가 없어 fatal이 난다.
- `KAKAO_NATIVE_APP_KEY`도 App 타깃 Info.plist에 있어야 한다.

해결:

- `Projects/App/Sources/AppCore/AppSDKInitializer.swift`에서 V0 AppDelegate의 Kakao/Naver 초기화를 수행한다.
- `Projects/App/Sources/PopPangApp.swift`의 `init()`에서 `AppSDKInitializer.configure()`를 호출한다.
- `Projects/App/Project.swift`의 App Info.plist에 `KAKAO_NATIVE_APP_KEY`, `CFBundleURLTypes`, `LSApplicationQueriesSchemes`를 V0 기준으로 유지한다.

## Moya / Alamofire 모듈 해석 문제

증상:

- `Moya`가 `Alamofire` 모듈을 찾지 못한다.
- `no such module Alamofire` 또는 explicit module open 관련 오류가 발생한다.

해결:

`Tuist/Package.swift`에서 두 product를 동적 framework로 유지한다.

```swift
"Alamofire": .framework,
"Moya": .framework,
```

`Core`와 `Data`는 `Moya`를 직접 import할 수 있지만, 타깃 의존성은 `ThirdParty` 프로젝트 타깃으로 받는다.

## Firebase product type 주의

Firebase 계열은 기본 static 설정을 유지한다.

이유:

- Firebase 공식 문서는 SPM 배포를 static only로 안내한다.
- Firebase/Google 계열 product를 무리하게 전부 `.framework`로 강제하면 `swiftCompatibility*`, `UIUtilities`, `SwiftUICore` auto-link 관련 오류가 발생할 수 있다.
- 따라서 Firebase는 필요한 product만 `ThirdParty`에 선언하고 product type override는 최소화한다.

## Firebase Swift import 대신 ObjC bridge를 쓰는 이유

키워드: Firebase ObjC bridge, Firebase Objective-C runtime bridge, firebase objc

증상:

```text
Undefined symbols for architecture arm64:
  _FIRGetLoggerLevel
  _FIRIsLoggableLevel
  _FIRSetLoggerLevelError
  ...
clang: error: linker command failed with exit code 1
```

재현 조건:

- `Projects/App` source에서 `import FirebaseCore` 후 `FirebaseApp.configure()` 또는 `FirebaseConfiguration.shared.setLoggerLevel(...)`를 직접 호출한다.
- `Projects/App` source에서 `import FirebaseAnalytics` 후 `Analytics.logEvent(...)`를 직접 호출한다.
- Firebase product type은 static 기본값을 유지하고, 외부 SDK 선언은 `ThirdParty`에 모아둔 상태다.

원인:

- Firebase SPM product는 static/auto-link 의존이 많다.
- App source가 Firebase Swift module을 직접 import하면 App 링크 단계에서 `FirebaseCoreInternal`, `GoogleAppMeasurement` 등 내부 전이 심볼이 직접 필요해진다.
- 이때 Tuist의 ThirdParty 허브 구조와 Firebase static product 조합에서 일부 내부 심볼이 App 링크에 충분히 전파되지 않아 undefined symbols가 발생할 수 있다.
- Firebase product를 전부 `.framework`로 강제하는 방식은 이전에 다른 auto-link 오류를 만들었으므로 기본 해결책으로 쓰지 않는다.

현재 해결:

- Firebase SDK product 선언은 계속 `Projects/Shared/ThirdParty/Project.swift`에만 둔다.
- `Projects/App` source에서는 `FirebaseCore`, `FirebaseAnalytics`, `FirebaseMessaging`을 직접 import하지 않는다.
- V0의 `FirebaseApp.configure()` 역할은 `FIRApp` Objective-C runtime bridge로 호출한다.
- V0의 `FirebaseLogger.trackScreen(_:)` 역할은 `FIRAnalytics.logEventWithName:parameters:` bridge로 호출한다.
- V0의 FCM token 수신/저장 흐름은 `FIRMessaging` bridge로 delegate와 APNs token만 연결한다.

관련 파일:

- `Projects/App/Sources/AppCore/AppSDKInitializer.swift`
- `Projects/App/Sources/AppCore/FirebaseLogger.swift`
- `Projects/App/Sources/AppCore/AppNotificationManager.swift`
- `Docs/logger.md`

주의:

- 이 bridge는 Firebase를 숨기기 위한 wrapper 전략이 아니라, Firebase static product 링크 오류를 피하기 위한 App 조립 계층의 예외다.
- 일반 외부 SDK는 기존 원칙대로 실제 SDK 모듈명을 직접 import한다.
- Firebase Swift API를 다시 직접 import하려면 먼저 `xcodebuild ... PopPangApp` 링크 검증에서 `_FIR...` undefined symbol이 재현되지 않는지 확인해야 한다.

## Tuist generate static product warning

증상:

```text
Target 'KakaoSDKCommon' has been linked from target 'Data' and target 'ThirdParty',
it is a static product so may introduce unwanted side effects.
```

의미:

- 같은 static SPM product가 여러 타깃에 직접 링크되고 있다.
- 런타임 duplicate class, casting failure, mysterious crash로 이어질 수 있다.

해결 순서:

1. warning에 나온 product가 `Projects/*/Project.swift` 여러 곳에 `.external(...)`로 선언되어 있는지 확인한다.
2. 직접 `.external(...)`을 제거하고 `ThirdParty` 프로젝트 타깃 의존성으로 바꾼다.
3. 그래도 링크 실패가 나면 `Tuist/Package.swift`에서 해당 product type override가 필요한지 최소 범위로 조정한다.
4. `tuist generate` 경고가 사라지고 앱 빌드가 통과하는지 확인한다.

## 현재 검증 명령

```sh
tuist generate
xcodebuild -workspace PopPang.xcworkspace -scheme PopPangApp -destination 'platform=iOS Simulator,name=iPhone 16,OS=18.5' build
```

현재 기준:

- `tuist generate` 성공
- static product 중복 링크 warning 없음
- `Coordinator` 테스트 성공
- `PopPangApp` 테스트 성공
- `PopPangApp` 테스트 실행 로그에서 KakaoSDKCommon duplicate class 경고 없음
- `KakaoSDKCommon.framework` 빌드/복사 로그는 정상이다. 문제가 되는 로그는 `Class _TtC14KakaoSDKCommon... is implemented in both` 형태다.
