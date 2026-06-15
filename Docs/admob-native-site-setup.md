# AdMob Native 광고 설정과 개발 순서

기준일: 2026-06-05

이 문서는 PopPang iOS 앱에 AdMob Native 광고를 붙일 때 필요한 작업을 사이트 설정부터 Xcode/Tuist 설정, SDK 초기화, Home 화면 개발까지 한 순서로 정리한다.

## 현재 결론

PopPang은 Firebase를 이미 사용하므로 AdMob 앱을 Firebase 앱에 연결한 상태로 운영한다. 광고 표시 자체는 Firebase SDK가 아니라 Google Mobile Ads SDK가 담당한다.

현재 구현 방향:

- AdMob 사이트에서 iOS 앱과 Native 광고 단위를 만든다.
- `ADMOB_APP_ID`와 `ADMOB_NATIVE_AD_UNIT_ID` 두 값을 `Secrets.xcconfig`에 둔다.
- `GADApplicationIdentifier`, `SKAdNetworkItems`, `ADMOB_NATIVE_AD_UNIT_ID`는 `Projects/App/Project.swift`에서 Info.plist 값으로 생성한다.
- SDK는 `Tuist/Package.swift`에 Google Mobile Ads SPM 패키지로 추가한다.
- 앱 시작 시 Firebase 초기화 후 `MobileAds.shared.start(completionHandler: nil)`을 한 번 호출한다.
- Home Native 광고는 `HomeFeature`의 Presentation 계층에서만 처리한다.
- Debug 빌드는 Google 공식 Native 테스트 광고 단위 ID를 사용하고, Release 빌드는 `ADMOB_NATIVE_AD_UNIT_ID`를 사용한다.

## ID 구분

AdMob에서 받는 ID는 생김새와 용도가 다르다.

| 값 | 예시 형식 | 저장 위치 | 용도 |
| --- | --- | --- | --- |
| AdMob 앱 ID | `ca-app-pub-xxxxxxxxxxxxxxxx~yyyyyyyyyy` | `ADMOB_APP_ID` | 앱 전체 식별자. Info.plist의 `GADApplicationIdentifier`로 들어간다. |
| Native 광고 단위 ID | `ca-app-pub-xxxxxxxxxxxxxxxx/yyyyyyyyyy` | `ADMOB_NATIVE_AD_UNIT_ID` | 실제 Native 광고 요청에 사용한다. |
| Native 테스트 광고 단위 ID | `ca-app-pub-3940256099942544/3986624511` | `Constants.AdMob.testNativeAdUnitId` | Google 공식 Demo ID. Debug 개발 중에만 사용한다. |

정리하면 `~`가 들어간 값은 앱 ID, `/`가 들어간 값은 광고 단위 ID다.

## 1. AdMob 사이트에서 앱 등록

AdMob:

```text
https://admob.google.com
```

경로:

```text
Apps
> Add app
> Platform: iOS
```

앱이 App Store에 아직 없으면 `No`를 선택하고 앱 이름과 플랫폼만으로 먼저 등록한다. 앱이 출시된 뒤에는 App Store listing을 다시 연결한다.

PopPang 기준:

| 항목 | 값 |
| --- | --- |
| 플랫폼 | iOS |
| 앱 이름 | PopPang 또는 팝팡 |
| Bundle ID | `kr.co.poppang.PopPang` |
| 광고 형식 | Native |

앱 등록 후 AdMob 앱 ID를 복사한다.

```text
ca-app-pub-xxxxxxxxxxxxxxxx~yyyyyyyyyy
```

이 값은 `ADMOB_APP_ID`에 넣는다.

## 2. Firebase 연결

Firebase를 이미 쓰는 앱이면 AdMob 앱을 Firebase 앱에 연결한다.

AdMob 경로:

```text
Apps
> PopPang
> App settings 또는 Firebase 연결 영역
> 기존 Firebase 프로젝트/앱 연결
```

확인할 것:

- Firebase 앱의 Bundle ID와 AdMob 앱의 Bundle ID가 같아야 한다.
- Google Analytics가 켜져 있으면 AdMob 사용자 측정항목과 Firebase Analytics를 같이 볼 수 있다.
- Firebase 연결은 분석과 수익 데이터 연동을 위한 것이고, 광고를 화면에 띄우는 코드는 Google Mobile Ads SDK로 작성한다.

### 노출 수준 광고 수익 설정

AdMob에서 다음 문구가 나오면 켜는 쪽으로 진행한다.

```text
노출 수준 광고 수익을 사용 설정하시겠습니까?
앱이 Firebase에 연결되어 있습니다...
```

의미:

- 광고 1회 노출마다 추정 수익 데이터를 Firebase/Analytics 쪽으로 넘길 수 있게 하는 설정이다.
- 광고 표시 기능 자체를 켜는 버튼은 아니다.
- Firebase와 AdMob을 연결해서 수익 분석까지 보려면 켜는 것이 맞다.

## 3. Native 광고 단위 생성

AdMob 경로:

```text
Apps
> PopPang
> Ad units
> Add ad unit
> Native
```

광고 단위 이름은 위치와 형식이 드러나게 만든다.

예시:

```text
iOS_Home_Native
iOS_PopupDetail_Native
iOS_SearchResult_Native
```

생성 후 Native 광고 단위 ID를 복사한다.

```text
ca-app-pub-xxxxxxxxxxxxxxxx/yyyyyyyyyy
```

이 값은 `ADMOB_NATIVE_AD_UNIT_ID`에 넣는다.

## 4. Secrets.xcconfig 설정

AdMob 관련 시크릿 키는 두 개다.

```xcconfig
ADMOB_APP_ID = ca-app-pub-xxxxxxxxxxxxxxxx~yyyyyyyyyy
ADMOB_NATIVE_AD_UNIT_ID = ca-app-pub-xxxxxxxxxxxxxxxx/yyyyyyyyyy
```

역할:

- `ADMOB_APP_ID`: 앱 시작 시 Google Mobile Ads SDK가 앱을 식별하기 위해 Info.plist에서 읽는다.
- `ADMOB_NATIVE_AD_UNIT_ID`: Release에서 Native 광고를 로드할 때 사용한다.

Debug 테스트 광고 단위 ID는 Google 공식 Demo 값이므로 `Secrets.xcconfig`에 넣지 않고 `Constants.AdMob.testNativeAdUnitId`에 둔다.

## 5. Tuist Package 설정

Google Mobile Ads SDK는 SPM으로 추가한다.

파일:

```text
Tuist/Package.swift
```

현재 설정:

```swift
.package(
    url: "https://github.com/googleads/swift-package-manager-google-mobile-ads.git",
    exact: "13.4.0"
)
```

추가 후 실행:

```bash
tuist install
make regen
```

## 6. ThirdParty 링크 설정

AdMob SDK product는 `ADKit` 타깃에서 직접 링크한다.

파일:

```text
Projects/Shared/ADKit/Project.swift
```

현재 설정:

```swift
.external(name: "GoogleMobileAds"),
.sdk(name: "JavaScriptCore", type: .framework),
```

`JavaScriptCore.framework`는 Google Mobile Ads SDK 링크 과정에서 필요해서 같이 연결한다.

추가 참고:

- `ADKit` source는 `import GoogleMobileAds`로 `GADAdLoader`, `GADNativeAd`, `GADMediaView` 같은 SDK 타입을 직접 사용한다.
- Tuist가 생성한 `GoogleMobileAdsTarget.framework`는 실제 SDK 구현체를 재수출하는 용도라기보다 `GoogleMobileAds.xcframework`를 감싸는 래퍼 타깃에 가깝다.
- 그래서 `ADKit` dynamic framework 링크 단계에서는 wrapper target만으로 `_OBJC_CLASS_$_GAD...` 심볼이 충분히 연결되지 않을 수 있다.
- 이 경우 `ADKit`의 `OTHER_LDFLAGS`에 아래 값을 추가해 실제 바이너리를 명시적으로 링크한다.

```swift
"OTHER_LDFLAGS": "$(inherited) -ObjC -framework GoogleMobileAds -framework UserMessagingPlatform"
```

- 핵심은 `GoogleMobileAdsTarget.framework` 같은 wrapper target 간접 링크에만 기대지 않고, `GoogleMobileAds.framework`와 관련 전이 framework를 `ADKit`이 직접 링크하게 만드는 것이다.
- `UserMessagingPlatform`을 같이 직접 링크하는 이유는, AdMob 관련 링크 책임을 다시 wrapper target 쪽에 일부 남겨두지 않고 `ADKit` 한 곳으로 모으기 위해서다.
- 즉 `GoogleMobileAds` 본체만 직접 링크하고 전이 framework는 계속 wrapper target에 맡기면 링크 경로가 다시 섞일 수 있으므로, AdMob 관련 바이너리 책임을 같은 규칙으로 직접 명시한다.

## 7. Info.plist 설정

이 프로젝트는 생성된 Xcode의 Info.plist를 직접 고치지 않는다. Tuist가 `Projects/App/Project.swift`의 `infoPlist` 설정으로 생성한다.

파일:

```text
Projects/App/Project.swift
```

현재 AdMob 관련 키:

```swift
"ADMOB_NATIVE_AD_UNIT_ID": "$(ADMOB_NATIVE_AD_UNIT_ID)",
"GADApplicationIdentifier": "$(ADMOB_APP_ID)",
"SKAdNetworkItems": [
    ["SKAdNetworkIdentifier": "cstr6suwn9.skadnetwork"],
    ...
],
```

### GADApplicationIdentifier

`GADApplicationIdentifier`에는 AdMob 앱 ID가 들어간다.

```text
ca-app-pub-xxxxxxxxxxxxxxxx~yyyyyyyyyy
```

이 값이 없으면 Google Mobile Ads SDK 초기화 시 앱이 비정상 종료될 수 있다.

### ADMOB_NATIVE_AD_UNIT_ID

`ADMOB_NATIVE_AD_UNIT_ID`는 앱 런타임에서 광고 단위 ID를 읽기 위해 Info.plist에 같이 넣는다.

Release에서 `Constants.AdMob.nativeAdUnitId`가 이 값을 읽는다.

### SKAdNetworkItems

`SKAdNetworkItems`는 Apple의 SKAdNetwork 전환 측정을 위해 광고 네트워크 식별자를 Info.plist에 등록하는 값이다.

쉽게 말하면:

- 광고를 보여주는 기능 자체의 필수 스위치는 아니다.
- 하지만 광고주 입장에서는 광고 성과 측정이 되는 앱이 더 유리하다.
- 측정이 잘 되면 광고 수요, 캠페인 참여, 단가 최적화에 유리할 수 있다.
- 그래서 AdMob 공식 iOS 설정 문서의 식별자 목록을 `Project.swift`에 넣어둔다.

식별자 목록은 한 번 넣고 끝이 아니라 Google 문서 기준으로 변경될 수 있으므로 SDK 업데이트 시 같이 확인한다.

## 8. SDK 초기화

파일:

```text
Projects/App/Sources/AppCore/AppSDKInitializer.swift
```

현재 순서:

```swift
FirebaseCoreBootstrap.configureIfNeeded()
ADKitBootstrap.start()
KakaoSDK.initSDK(appKey: Constants.KakaoAPI.key)
NMFAuthManager.shared().ncpKeyId = Constants.NaverAPI.key
```

기준:

- 앱 실행 중 한 번만 호출한다.
- 광고를 로드하기 전에 호출되어야 한다.
- Firebase를 쓰는 프로젝트이므로 Firebase 초기화 후 바로 호출한다.
- Firebase 문서의 예전 Swift 예시는 `GADMobileAds.sharedInstance().start(...)` 형태로 보일 수 있지만, 현재 Google Mobile Ads Swift API에서는 `MobileAds.shared.start()` 형태를 사용한다.
- AdMob 초기화 호출은 `App`에 직접 두지 않고 `ADKitBootstrap.start()`로 감싼다. 이렇게 하면 AdMob SDK 직접 의존 경계가 `ADKit` 하나로 모인다.

## 9. AdMob 상수 연결

파일:

```text
Projects/Shared/Core/Sources/Support/Constants.swift
```

현재 설정:

```swift
public enum AdMob {
    public static let nativeAdUnitId = AppConfig.string(forKey: "ADMOB_NATIVE_AD_UNIT_ID")
    public static let testNativeAdUnitId = "ca-app-pub-3940256099942544/3986624511"

    public static var currentNativeAdUnitId: String {
        #if DEBUG
            testNativeAdUnitId
        #else
            nativeAdUnitId
        #endif
    }
}
```

역할:

- `nativeAdUnitId`: Release에서 실제 광고 요청에 사용한다.
- `testNativeAdUnitId`: Debug에서 Google 공식 테스트 Native 광고를 요청한다.
- `currentNativeAdUnitId`: 빌드 환경에 맞게 Debug는 테스트 ID, Release는 실제 ID를 반환한다.

## 10. Native 광고 로드 구조

Home Native 광고는 Domain, UseCase, Repository로 내리지 않는다.

이유:

- 광고 로드는 비즈니스 도메인 규칙이 아니라 화면 수익화 UI 관심사다.
- 현재는 Home 화면 한 위치에 붙는 SDK UI 컴포넌트다.
- 서버 데이터와 섞지 않고 `HomeFeature` Presentation 안에서 끝내는 편이 변경 범위가 작다.
- Compound 상태에는 팝업 목록, 필터, 딥링크처럼 Home 기능 상태만 유지한다.

파일:

```text
Projects/Features/HomeFeature/Sources/Presentation/NativeAd/HomeNativeAdViewModel.swift
```

현재 흐름:

```swift
init(adUnitID: String = Constants.AdMob.currentNativeAdUnitId) {
    self.adUnitID = adUnitID
}
```

로드 방식:

```swift
let mediaOptions = NativeAdMediaAdLoaderOptions()
mediaOptions.mediaAspectRatio = .landscape

let adLoader = AdLoader(
    adUnitID: adUnitID,
    rootViewController: nil,
    adTypes: [.native],
    options: [mediaOptions]
)
adLoader.delegate = self
adLoader.load(Request())
```

`mediaAspectRatio = .landscape`는 2열 grid 광고 셀에 더 잘 맞는 가로형 media를 선호한다는 뜻이다. Google 문서 기준으로 이 값은 선호 옵션이며, 모든 광고 소재가 해당 비율로 내려온다고 보장되지는 않는다.

성공하면 `NativeAd`를 `@Published private(set) var nativeAd`에 보관하고, 실패하면 `errorMessage`에 실패 메시지를 둔다.

## 11. Native 광고 UI 구조

파일:

```text
Projects/Features/HomeFeature/Sources/Presentation/NativeAd/HomeNativeAdView.swift
```

구조:

- SwiftUI에서는 `HomeNativeAdGridCellView`를 사용한다.
- 실제 Google SDK 뷰는 `UIViewRepresentable`로 감싼다.
- UIKit 쪽 루트 뷰는 `NativeAdView`다.
- 이미지/비디오 영역은 `MediaView`다.
- Home grid의 기존 셀 크기와 맞추기 위해 `302` 높이 안에 compact 형태로 배치한다.

Native 광고에서 중요한 연결:

```swift
nativeAdView.mediaView = mediaView
nativeAdView.headlineView = headlineLabel
nativeAdView.callToActionView = callToActionButton
nativeAdView.nativeAd = nativeAd
```

주의:

- Native 광고는 단순히 SwiftUI 카드처럼 직접 그리는 것이 아니라 Google SDK의 `NativeAdView`에 에셋 뷰를 등록해야 한다.
- CTA 버튼은 SDK가 클릭을 처리해야 하므로 `callToActionView?.isUserInteractionEnabled = false`로 둔다.
- 광고임을 알 수 있게 `광고` 배지를 표시한다.

## 12. Home 화면 배치

파일:

```text
Projects/Features/HomeFeature/Sources/Presentation/HomeFeatureView.swift
```

현재 배치:

- `best` 섹션
- `coming` 섹션
- `grid` 섹션

Native 광고는 별도 섹션으로 만들지 않고, `grid` 섹션 안에서 팝업 셀 사이에 삽입한다.

광고 item 삽입 로직은 아래 파일에 둔다.

```text
Projects/Features/HomeFeature/Sources/Presentation/NativeAd/HomeNativeAdGridItem.swift
```

현재 삽입 규칙:

```swift
var gridItems: [HomeGridItem] {
    var items = compound.state.gridPopups.map(HomeGridItem.popup)
    guard nativeAdViewModel.nativeAd != nil, items.isEmpty == false else { return items }

    let insertIndex = min(4, items.count)
    items.insert(.nativeAd, at: insertIndex)
    return items
}
```

의미:

- 광고가 아직 로드되지 않았으면 기존 팝업 grid만 보여준다.
- 광고가 로드되면 팝업 4개 뒤에 `nativeAd` item을 하나 삽입한다.
- grid가 비어 있으면 광고만 단독으로 보여주지 않는다.
- 광고 셀도 기존 grid와 같은 `itemHeight: 302` 안에서 렌더링한다.

진입 시점:

```swift
.onAppear {
    compound.send(.onAppear)
    nativeAdViewModel.loadAdIfNeeded()
}
```

광고가 로드된 경우에만 grid item 목록에 광고 셀을 끼워 넣는다.

## 13. 테스트 광고 기준

개발 중에는 실제 광고 단위 ID를 직접 클릭 테스트하지 않는다.

Debug 기준:

```text
ca-app-pub-3940256099942544/3986624511
```

이 값은 Google 공식 iOS Native 테스트 광고 단위 ID다. 개발자 개인 AdMob 계정에서 발급받은 키가 아니다.

Release 기준:

```text
ADMOB_NATIVE_AD_UNIT_ID
```

실제 광고 단위 ID로 테스트해야 하면 AdMob의 테스트 기기 등록을 사용한다.

경로:

```text
AdMob
> Settings
> Test devices
> Add test device
```

금지:

- 개발자나 QA가 실제 광고를 반복 클릭하지 않는다.
- 테스트 모드 표시가 없는 광고를 디버깅 목적으로 누르지 않는다.

## 14. 검증 명령

Tuist 설정을 바꾼 뒤:

```bash
make regen
```

HomeFeature 단위 빌드:

```bash
tuist build HomeFeature
```

앱 전체 빌드:

```bash
tuist build PopPangApp
```

현재 확인된 결과:

- `make regen` 성공
- `tuist build HomeFeature` 성공
- `tuist build PopPangApp` 성공

## 15. 출시 전 체크리스트

- `Secrets.xcconfig`의 `ADMOB_APP_ID`가 `~` 형식 앱 ID인지 확인한다.
- `Secrets.xcconfig`의 `ADMOB_NATIVE_AD_UNIT_ID`가 `/` 형식 Native 광고 단위 ID인지 확인한다.
- Release 빌드에서 테스트 광고 ID가 사용되지 않는지 확인한다.
- AdMob 앱 상태와 광고 단위 상태가 준비됨인지 확인한다.
- App Store 출시 후 AdMob 앱을 App Store listing에 연결한다.
- app-ads.txt가 필요한 상태인지 AdMob 콘솔에서 확인한다.
- EEA 등 사용자 동의가 필요한 지역을 위해 UMP 동의 플로우 적용 여부를 결정한다.
- ATT 권한 요청이 필요한 광고 전략인지 확인한다.
- 실제 광고 클릭 테스트를 하지 않는다.
- SDK 업데이트 시 `SKAdNetworkItems` 목록 변경 여부를 다시 확인한다.

## 참고 문서

- Firebase와 함께 AdMob iOS 시작하기: https://firebase.google.com/docs/admob/ios/quick-start?hl=ko
- Google Mobile Ads SDK iOS 설정: https://developers.google.com/admob/ios/quick-start?hl=ko
- iOS Native Advanced 광고 구현: https://developers.google.com/admob/ios/native/advanced?hl=ko#swiftui
- iOS 테스트 광고 단위 ID: https://developers.google.com/admob/ios/test-ads
- iOS 개인정보 보호 전략과 SKAdNetwork: https://developers.google.com/admob/ios/privacy/strategies?hl=ko#enable_skadnetwork_to_track_conversions
- Apple SKAdNetworkItems: https://developer.apple.com/documentation/BundleResources/Information-Property-List/SKAdNetworkItems
