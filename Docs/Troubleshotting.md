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
- legacy coordinator 구조에서는 각 탭 coordinator가 팝업 선택 이벤트를 상위 coordinator로 전달했다.
- 현재 TCA 구조에서는 각 feature가 `.delegate(.popupSelected(...))` action을 올리고, `MainTabFeature`가 `Path.popupDetail`을 `StackState`에 append한다.
- `MainTabFeatureView`가 하나의 상위 `NavigationStack`으로 `TabView`를 감싸고, `MainTabFeature.Path.popupDetail`을 상위 destination으로 push한다.
- 상위 destination으로 열린 `PopupDetailFeatureView`는 `hidesSystemTabBar: false`로 생성한다. 이 화면은 이미 `TabView` 바깥 destination이라 숨길 탭바가 없다.

주의:

- 탭 내부 route로 상세를 push하는 fallback 경로는 아직 있을 수 있으므로 `PopupDetailFeatureView`의 기본값은 `hidesSystemTabBar: true`로 유지한다.
- V0와 같은 체감을 원하면 사용자 플로우의 팝업 상세 진입점은 가능한 상위 route로 모아야 한다.
- 상위 `NavigationStack`에 typed path 배열을 두고, 탭 내부에도 각기 다른 typed path의 `NavigationStack`을 중첩하면 SwiftUI가 내부 path 비교 중 `AnyNavigationPath.Error.comparisonTypeMismatch`로 크래시할 수 있다. 그래서 공통 상세 route는 `MainTabFeature.Path`의 단일 `StackState`로 모은다.

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
- 예외적으로 AdMob 런타임 구현은 `ADKit`이 직접 `GoogleMobileAds`와 `JavaScriptCore`를 링크한다.
- wrapper/adapter는 기본 전략이 아니다. 꼭 필요할 때만 별도 판단한다.

### ADKit에서 GAD 심볼이 링크되지 않는 경우

증상:

```text
Undefined symbol: _GADAdLoaderAdTypeNative
Undefined symbol: _OBJC_CLASS_$_GADAdLoader
Undefined symbol: _OBJC_CLASS_$_GADMediaView
Undefined symbol: _OBJC_CLASS_$_GADNativeAd
```

원인:

- `ADKit`은 `import GoogleMobileAds`로 AdMob 타입을 직접 사용한다.
- 하지만 Tuist가 생성한 `GoogleMobileAdsTarget.framework`는 실제 SDK 구현체를 재수출하는 프레임워크라기보다 `GoogleMobileAds.xcframework`를 감싸는 wrapper target에 가깝다.
- 그래서 `ADKit.framework` 링크 단계에서 wrapper target 간접 링크만으로는 `_OBJC_CLASS_$_GAD...` Objective-C 심볼이 충분히 붙지 않을 수 있다.

해결:

- `Projects/Shared/ADKit/Project.swift`에서 `GoogleMobileAds`와 `JavaScriptCore`를 직접 의존한다.
- 그리고 `ADKit` target의 `OTHER_LDFLAGS`에 아래 값을 추가해 실제 SDK 바이너리를 명시적으로 링크한다.

```swift
"OTHER_LDFLAGS": "$(inherited) -ObjC -framework GoogleMobileAds -framework UserMessagingPlatform"
```

왜 `UserMessagingPlatform`도 같이 넣는가:

- 이번 문제의 본질은 wrapper target 간접 링크에 기대던 경로가 `ADKit.framework` 링크 단계에서 충분하지 않았다는 점이다.
- 그래서 `GoogleMobileAds`만 직접 링크하고 나머지 전이 framework는 계속 wrapper target 쪽에 남겨두면 링크 책임이 다시 분산될 수 있다.
- `UserMessagingPlatform`까지 함께 직접 링크하면 AdMob 관련 바이너리 책임을 `ADKit` 한 곳으로 모을 수 있고, direct link/indirect link 경로가 섞이지 않는다.

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
- `FirebaseMessaging`과 `FirebaseCoreInternal`만 `.framework`로 고정하면 빌드는 통과하지만, 디바이스 실행 시 LLDB가 동적 framework 심볼을 읽느라 앱 실행 대기가 길어질 수 있다.

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
- V0의 FCM token 수신/저장 흐름은 `FIRMessaging` bridge로 delegate, APNs token, 명시적 token 요청을 연결한다.

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

## Firebase static product에서 FIRApp/FIRMessaging class를 찾지 못하는 문제

기준일: 2026-06-04

### 증상

앱 실행 초기에 Firebase 초기화와 FCM 토큰 요청이 실패한다.

```text
[AppSDKInitializer:26] configureIfNeeded() - ❌ FIRApp class를 찾지 못했습니다.
[AppNotificationManager:213] messagingInstance() - ❌ FIRMessaging class를 찾지 못했습니다.
[AppNotificationManager:136] requestCurrentFCMToken(reason:) - ❌ FCM 토큰 요청 실패(APNs 토큰 등록 직후): FIRMessaging 인스턴스를 찾지 못했습니다.
```

이 로그가 뜨면 Firebase가 configure 되지 않았고, `Messaging.messaging()`도 사용할 수 없는 상태다. APNs 디바이스 토큰을 받더라도 Firebase Messaging에 전달할 인스턴스가 없어서 FCM 토큰 발급이 실패한다.

### 문제의 핵심

이 문제는 "Firebase를 static으로 둬서 느리다"가 아니다. Firebase product type은 Tuist 기본값인 static 계열로 두는 것이 현재 기준이다.

실제 문제는 App 코드가 Firebase SDK 타입을 직접 참조하지 않고 아래처럼 Objective-C runtime 문자열 조회만 사용한 점이다.

```swift
NSClassFromString("FIRApp")
NSClassFromString("FIRMessaging")
NSClassFromString("FIRAnalytics")
```

`NSClassFromString`은 런타임에 문자열 이름으로 class를 찾아보는 API다. 이 호출은 `FirebaseApp`, `Messaging`, `Analytics` 같은 Firebase 타입에 대한 컴파일 타임 참조나 강한 링크 참조를 만들지 않는다.

static product에서는 linker가 "실제로 필요하다고 판단한 object file" 위주로 최종 바이너리에 포함한다. Firebase 타입을 직접 참조하지 않고 문자열로만 찾으면 linker 입장에서는 `FIRApp`, `FIRMessaging` 관련 Objective-C class metadata를 반드시 살려야 한다는 근거가 약해진다. 그 결과 의존성 그래프에 Firebase가 있어도 Objective-C runtime에 해당 class가 등록되지 않을 수 있다.

그래서 런타임에서 `FIRApp class를 찾지 못했습니다`, `FIRMessaging class를 찾지 못했습니다`가 발생한다.

### 잘못된 해결 방향

Firebase product를 dynamic framework로 강제하는 방식은 기본 해결책이 아니다.

- `FirebaseMessaging`과 `FirebaseCoreInternal`만 `.framework`로 고정하면 class lookup 문제는 겉으로 줄어들 수 있다.
- 하지만 디바이스 실행 시 LLDB가 동적 framework 심볼을 읽는 시간이 늘어 실행 대기가 길어질 수 있다.
- Firebase/Google 계열 product를 넓게 dynamic으로 강제하면 `swiftCompatibility*`, `UIUtilities`, auto-link 계열 링크 문제가 다시 생길 수 있다.

따라서 product type을 dynamic으로 바꾸기 전에 static 링크를 올바르게 구성해야 한다.

### 해결 원칙

해결은 세 가지를 함께 맞춘다.

1. Firebase product type은 `Tuist/Package.swift`에서 별도 override하지 않는다.
2. Firebase SDK를 쓰는 App source 파일은 실제 Firebase 모듈을 직접 import하고 실제 SDK API를 호출한다.
3. `ThirdParty` 타깃에는 Objective-C class/category가 dead strip 되지 않도록 `-ObjC` linker flag를 둔다.

### 실제 코드 기준

`Projects/App/Sources/AppCore/AppSDKInitializer.swift`

```swift
import FirebaseCore

FirebaseConfiguration.shared.setLoggerLevel(.error)
if FirebaseApp.app() == nil {
    FirebaseApp.configure()
}
```

`Projects/App/Sources/AppCore/AppNotificationManager.swift`

```swift
import FirebaseMessaging

final class AppNotificationManager: NSObject, UNUserNotificationCenterDelegate, MessagingDelegate {
    func configureNotification(...) {
        Messaging.messaging().delegate = self
    }

    func didRegisterForRemoteNotifications(deviceToken: Data) {
        Messaging.messaging().apnsToken = deviceToken
        Messaging.messaging().token { token, error in
            ...
        }
    }

    func messaging(_ messaging: Messaging, didReceiveRegistrationToken fcmToken: String?) {
        ...
    }
}
```

`Projects/App/Sources/AppCore/FirebaseLogger.swift`

```swift
import FirebaseAnalytics

Analytics.logEvent("screen_view", parameters: [
    "firebase_screen": name,
    "firebase_screen_class": name,
])
```

### ThirdParty linker flag

`Projects/Shared/ThirdParty/Project.swift`

```swift
settings: .settings(
    base: [
        "OTHER_LDFLAGS": "$(inherited) -ObjC",
    ]
)
```

의미:

- `OTHER_LDFLAGS`는 Xcode의 Linker Flags 설정이다. Swift/Objective-C 컴파일 옵션이 아니라 최종 바이너리를 링크할 때 linker에게 전달되는 옵션이다.
- `$(inherited)`는 상위 설정, xcconfig, Tuist/SPM이 이미 넣어둔 linker flag를 유지한다는 뜻이다. 이 값을 빼면 기존 자동 링크 옵션을 덮어써서 다른 SDK 링크가 깨질 수 있다.
- `-ObjC`는 정적 라이브러리나 static framework 안의 Objective-C class/category 심볼을 더 적극적으로 로드하게 하는 linker 옵션이다.
- Firebase iOS SDK는 Swift API를 쓰더라도 내부에 Objective-C runtime class와 category가 많다. static product 조합에서 필요한 Objective-C class가 dead strip 되면 `FIRApp`, `FIRMessaging` 같은 class가 런타임에 등록되지 않을 수 있다.
- `-ObjC`는 Firebase를 dynamic으로 바꾸는 설정이 아니다. static product를 유지하면서 Objective-C runtime 등록 누락을 막기 위한 보조 설정이다.

`-ObjC`만으로 충분하지 않다. App source에서 `FirebaseApp`, `Messaging`, `Analytics` 같은 실제 SDK 타입을 직접 참조해야 static 링크가 확실히 살아난다.

### Tuist 설정 기준

- `Tuist/Package.swift`에서 Firebase product type은 별도 override하지 않는다.
- `FirebaseCore`, `FirebaseMessaging`, `FirebaseAnalytics`는 `Projects/Shared/ThirdParty/Project.swift`의 `.external(...)`에 유지한다.
- App은 `ThirdParty` 프로젝트 타깃에 의존한다.
- Firebase를 쓰는 App source 파일은 `import FirebaseCore`, `import FirebaseMessaging`, `import FirebaseAnalytics`처럼 실제 SDK 모듈명을 직접 import한다.
- 이 방식은 하루한컷 v2의 Firebase 조립 방식과 같은 방향이다.

### 검증

```sh
make regen
xcodebuild -workspace PopPang.xcworkspace -scheme PopPangApp -destination 'generic/platform=iOS Simulator' build
```

확인할 것:

- `make regen` 후 `Projects/Shared/ThirdParty/ThirdParty.xcodeproj/project.pbxproj`에 `OTHER_LDFLAGS = "$(inherited) -ObjC";`가 반영되어야 한다.
- App 빌드가 성공해야 한다.
- 실행 로그에서 `FIRApp class를 찾지 못했습니다`, `FIRMessaging class를 찾지 못했습니다`가 다시 나오면 안 된다.

## 실기기 Debug executable 실행 대기 시간이 긴 문제

기준일: 2026-06-04

### 증상

실기기에서 Xcode로 앱을 실행할 때만 실행 전 대기 시간이 길다.

예시:

- 시뮬레이터 실행은 빠르다.
- 실기기에서 Xcode Run을 누르면 앱이 뜨기 전 10초 안팎 대기한다.
- Xcode 연결을 끊고 실기기에서 앱 아이콘으로 직접 실행하면 빠르다.
- Scheme의 `Debug executable`을 끄면 실기기 Xcode 실행도 빨라진다.

이 조합이면 앱 코드의 startup 지연보다 Xcode 디버거 attach 비용을 먼저 의심한다.

### Debug executable 의미

위치:

```text
Xcode > Product > Scheme > Edit Scheme... > Run > Info > Debug executable
```

`Debug executable`은 Xcode가 앱 실행 시 LLDB 디버거를 앱 프로세스에 붙일지 결정하는 옵션이다.

켜져 있으면:

- 브레이크포인트가 동작한다.
- 변수 보기, call stack, thread 상태 확인이 가능하다.
- LLDB 콘솔에서 `po`, `bt` 같은 명령을 사용할 수 있다.
- crash 또는 exception 지점에서 Xcode가 멈출 수 있다.
- 대신 실기기에서는 앱 시작 전에 `debugserver` 연결, LLDB attach, Swift/ObjC symbol loading 비용이 든다.

꺼져 있으면:

- Xcode가 앱 설치와 실행은 하지만 LLDB를 붙이지 않는다.
- 브레이크포인트가 잡히지 않는다.
- 변수 보기, call stack 확인, LLDB 명령 사용이 불가능하다.
- crash 지점에서 자동으로 멈춰 원인을 보여주지 않는다.
- 대신 기기에서 앱 아이콘으로 직접 실행하는 것과 더 가까운 속도로 뜬다.

### 왜 실기기에서 더 느린가

실기기 Debug 실행은 앱 코드만 실행하는 과정이 아니다.

Xcode가 실행 전에 다음 작업을 수행한다.

1. 앱 설치와 서명 검증
2. `debugserver` 연결
3. LLDB attach
4. 앱 실행 파일과 dynamic framework 이미지 로드 확인
5. Swift/Objective-C symbol loading
6. 브레이크포인트와 소스 위치 매핑
7. dSYM/debug info 연결

현재 PopPang은 Tuist 멀티 모듈 구조이고, Debug 산출물에 여러 dynamic framework가 포함된다. dynamic framework가 많을수록 실기기에서 LLDB가 읽고 매핑해야 하는 이미지와 심볼도 늘어난다.

따라서 `Debug executable`을 켰을 때만 느리고, 끄거나 기기에서 직접 실행하면 빠른 경우는 Firebase 초기화 지연이나 앱 코드 성능 문제가 아니라 디버거 준비 시간일 가능성이 높다.

### 판단 기준

아래 조건이 모두 맞으면 앱 startup 성능 문제가 아니라 디버거 attach 문제로 본다.

- `Debug executable` ON: 실기기 실행 전 대기 시간이 길다.
- `Debug executable` OFF: 실기기 실행이 빠르다.
- Xcode 없이 앱 아이콘 직접 실행: 빠르다.
- 시뮬레이터 실행: 상대적으로 빠르다.

반대로 `Debug executable`을 꺼도 느리거나, 앱 아이콘 직접 실행도 느리면 앱 코드 startup, SDK 초기화, 네트워크 preload, 런치 화면 전환 로직을 별도로 추적한다.

### 사용 기준

평소 UI 확인과 플로우 점검:

- `Debug executable` OFF를 사용한다.
- 실제 사용자 체감 실행 속도 확인도 OFF 또는 기기 직접 실행 기준으로 본다.

문제 추적:

- 브레이크포인트가 필요하면 `Debug executable` ON을 사용한다.
- 변수 값, reducer/action 흐름, async task, delegate callback, deep link, push callback을 추적할 때 ON이 필요하다.
- crash 지점을 Xcode에서 멈춰 확인해야 할 때 ON이 필요하다.

주의:

- `Debug executable` OFF에서 빠르다고 해서 Release 성능 검증을 대체하지는 않는다.
- 실제 배포 성능은 Release 또는 TestFlight 빌드 기준으로 확인한다.
- `Debug executable` ON에서만 10초 안팎 대기하는 현상은 실기기 디버깅 비용일 수 있으며, 그 자체만으로 앱 startup regression으로 판단하지 않는다.

## 릴리스 빌드 지도 탭 진입 시 BottomSheet duplicate class 크래시

기준일: 2026-06-05

### 증상

릴리스 빌드에서 앱 실행 후 팝팡지도 탭에 진입하면 잠깐 멈춘 뒤 크래시가 난다.

대표 로그:

```text
objc[...] Class _TtC11BottomSheet24BottomSheetConfiguration is implemented in both
.../PopPangApp.app/Frameworks/ThirdParty.framework/ThirdParty
and
.../PopPangApp.app/Frameworks/Coordinator.framework/Coordinator
This may cause spurious casting failures and mysterious crashes.
One of the duplicates must be removed or renamed.

=== AttributeGraph: cycle detected through attribute ... ===
Error: distanvePerminWidth is 0
Thread 1: EXC_BAD_ACCESS
```

판단:

- `BottomSheetConfiguration is implemented in both ...`가 1차 원인이다.
- `AttributeGraph cycle`, layout warning, `distanvePerminWidth is 0`은 같이 보일 수 있지만, 이 로그 조합에서는 링크 중복으로 인한 런타임 클래스 충돌을 먼저 해결한다.
- 지도 탭에서 `BottomSheet`를 실제로 쓰기 시작하면서 중복 로딩 문제가 드러난다.

### 원인

현재 PopPang 구조:

```text
PopPangApp.app
 -> ThirdParty.framework
    -> BottomSheet

PopPangApp.app
 -> Coordinator.framework
    -> MapFeature.staticFramework
       -> import BottomSheet
```

`BottomSheet` SPM product가 기본 static product로 처리되면 다음 문제가 생긴다.

- `ThirdParty.framework`가 `BottomSheet` 코드를 포함한다.
- `MapFeature`는 `.staticFramework`라서 `Coordinator.framework`에 합쳐진다.
- `MapFeature`가 쓰는 `BottomSheet` 코드도 `Coordinator.framework` 안으로 들어갈 수 있다.
- 앱 실행 시 Objective-C/Swift 런타임이 같은 클래스인 `BottomSheetConfiguration`을 두 framework에서 발견한다.
- 그 결과 duplicate class 경고와 casting failure, `EXC_BAD_ACCESS`가 발생할 수 있다.

중요:

- 여러 Swift 파일에서 `import BottomSheet`를 쓰는 것 자체가 문제는 아니다.
- 문제는 같은 SDK 구현 코드가 여러 dynamic framework 바이너리 안에 각각 포함되는 것이다.

### 해결

`Tuist/Package.swift`의 `PackageSettings.productTypes`에서 `BottomSheet`를 dynamic framework로 고정한다.

```swift
let packageSettings = PackageSettings(
    productTypes: [
        "BottomSheet": .framework,
        ...
    ]
)
```

의미:

- `BottomSheet` 구현 코드를 `ThirdParty.framework`나 `Coordinator.framework` 안에 각각 복사하지 않는다.
- 앱 번들의 `BottomSheet.framework` 한 곳에서 로드되게 만든다.
- `BottomSheetConfiguration` 같은 런타임 클래스가 한 번만 등록되도록 한다.

`Projects/Shared/ThirdParty/Project.swift`의 `.external(name: "BottomSheet")`는 유지한다.

```swift
.external(name: "BottomSheet")
```

각 feature source에서는 실제 SDK 모듈명을 그대로 import한다.

```swift
import BottomSheet
```

### 언제 static framework를 쓰는가

아래 조건이면 `.staticFramework`가 기본 선택이다.

| 조건 | 예 | 이유 |
| --- | --- | --- |
| 앱 내부 전용 feature | `HomeFeature`, `MapFeature`, `SearchFeature` | 앱 밖에서 독립 SDK처럼 배포하지 않는다. |
| leaf 모듈 | `Feature -> Domain/Core/DSKit/ThirdParty` | 다른 여러 모듈이 feature 구현을 다시 공유하지 않는다. |
| feature 수가 많다 | `Projects/Features/*Feature` | 런타임 dynamic framework 수, embed/sign 대상, dyld 로드 비용을 줄인다. |
| 런타임 교체가 필요 없다 | 대부분의 PopPang feature | 바이너리 경계보다 실행 단순성이 중요하다. |

PopPang 기본 feature 설정:

```swift
product: .staticFramework
```

주의:

- static feature라도 source boundary와 import boundary는 유지된다.
- static은 "모듈이 아니다"라는 뜻이 아니다.
- static dependency가 여러 dynamic framework에 각각 들어가면 duplicate class 문제가 생길 수 있다.

### 언제 dynamic framework를 쓰는가

아래 조건이면 `.framework`가 맞다.

| 조건 | 예 | 이유 |
| --- | --- | --- |
| 여러 레이어가 공유하는 경계 | `Domain`, `Core`, `DSKit` | 여러 target이 명시적으로 import하는 계약/API 경계다. |
| 앱 조립 또는 인프라 경계 | `Data`, `ThirdParty` | App이 별도 framework로 조립하는 큰 경계다. |
| feature public interface | `SearchFeatureInterface`, `PopupDetailFeatureInterface` | 재사용 entry API를 명시적으로 노출한다. |
| static이면 duplicate class가 난 SPM product | `BottomSheet`, `KakaoSDKCommon` | 같은 SDK 코드가 여러 dynamic framework에 복사되는 것을 막는다. |
| static 기본값에서 링크/모듈 해석이 깨지는 SPM product | `Moya`, `Alamofire`, `GoogleSignIn` 전이 product | `no such module`, undefined symbols를 막는다. |

SPM product override 기준:

- 기본값으로 먼저 빌드한다.
- 문제가 재현된 product만 최소 범위로 `PackageSettings.productTypes`에 추가한다.
- `Class ... is implemented in both ...`가 나오면 해당 SDK 코드가 여러 dynamic framework에 들어갔는지 확인한다.
- Firebase 계열처럼 static 전제가 강한 SDK는 무리하게 dynamic으로 고정하지 않는다.

### 검증

프로젝트 재생성:

```sh
tuist install
tuist generate
```

생성된 프로젝트에서 확인:

```sh
rg -n "BottomSheet.framework" Projects/Shared/ThirdParty/ThirdParty.xcodeproj Projects/Features/MapFeature/MapFeature.xcodeproj Projects/App/App.xcodeproj -g "*.pbxproj"
```

기대:

- `BottomSheet` 프로젝트가 별도로 생성된다.
- App build phase에 `BottomSheet.framework`가 embed 대상 또는 copy files 대상으로 잡힌다.
- App과 feature 산출물 안에 `BottomSheetConfiguration` 구현이 중복 포함되지 않아야 한다.

릴리스 빌드 확인:

```sh
xcodebuild -workspace PopPang.xcworkspace \
  -scheme PopPangApp \
  -configuration Release \
  -destination 'platform=iOS Simulator,name=iPhone 16,OS=18.5' \
  build
```

실기기 또는 TestFlight에서 확인:

- 앱 실행 후 팝팡지도 탭에 진입한다.
- 로그에 `Class _TtC11BottomSheet24BottomSheetConfiguration is implemented in both`가 다시 나오면 아직 해결되지 않은 상태다.
- duplicate class 로그가 사라졌는데도 지도 탭에서 크래시가 나면 그때는 `AttributeGraph`, `BottomSheet` layout, NMapsMap marker/cluster 갱신을 별도 이슈로 분리해 추적한다.
