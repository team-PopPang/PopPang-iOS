# PopPang 모듈 구조

이 문서는 Tuist 모듈을 만들고 연결하는 기준이다. 모듈을 추가하거나 의존성, product type, 외부 패키지를 바꾸기 전에 읽는다. 모듈별 책임과 의존성 표는 [아키텍처](architecture.md#모듈-지도)에 있다.

## 목차

- [Tuist 구성](#tuist-구성)
- [Product type 기준](#product-type-기준)
- [Project.swift 작성 규칙](#projectswift-작성-규칙)
- [새 모듈 만들기](#새-모듈-만들기)
- [외부 패키지](#외부-패키지)
- [ThirdParty 허브](#thirdparty-허브)
- [생성물과 정리되지 않은 파일](#생성물과-정리되지-않은-파일)

## Tuist 구성

| 파일 | 내용 |
| --- | --- |
| `Tuist.swift` | `let tuist = Tuist()`. 별도 옵션이 없다. |
| `Workspace.swift` | workspace 이름은 `PopPang`. `Projects/{App,Features,Domain,Data,Shared}/**`를 포함한다. |
| `Tuist/Package.swift` | 외부 패키지 버전과 product type override |
| `Tuist/Templates/` | `make module`이 쓰는 scaffold 템플릿 |
| `Projects/**/Project.swift` | 모듈별 manifest. `ProjectDescriptionHelpers` 없이 직접 작성한다. |

Tuist 설치와 명령은 [Tuist 설치와 실행](../development/tuist.md)을 본다.

## Product type 기준

| 모듈 | product | 이유 |
| --- | --- | --- |
| `App` (`PopPangApp`) | `.app` | 앱 타깃 |
| `Domain`, `Data`, `Core`, `DSKit`, `ThirdParty`, `ADKit` | `.framework` | 여러 모듈이 공유하는 경계다. |
| `Features/*Feature` | `.staticFramework` | 앱 안에서만 쓰는 leaf feature다. 실행 시점에 따로 로드할 framework 수를 줄인다. |
| `PopPangRNFeature` | `.framework` | React Native prebuilt 패키지(`Vendor/PrebuiltReactNativeFrameworks`)를 링크한다. feature 중 유일하게 `.framework`다(이유는 코드에 적혀 있지 않음, `확인 필요`). |
| `*Tests` | `.unitTests` | |
| `*Demo` | `.app` | feature 단독 실행용 데모 앱 |

product type을 바꾸면 링크와 런타임 동작이 바뀐다(duplicate class, 심볼 누락 등). 바꾸기 전에 계획에 근거와 검증 방법(`PopPangApp` 빌드와 실행)을 적고 승인을 받는다.

`Tuist/Package.swift` 29~35행 주석은 모든 내부 모듈이 `.framework`라고 설명하지만 오래된 내용이다. 실제 기준은 위 표와 각 `Project.swift`다.

## Project.swift 작성 규칙

모든 타깃이 따르는 값:

- `destinations: [.iPhone]`
- `deploymentTargets: .iOS("17.0")`
- `infoPlist: .default` 또는 `.extendingDefault(with:)`

bundle id 형식:

| 타깃 | 형식 | 예 |
| --- | --- | --- |
| 앱 | `kr.co.poppang.PopPang` | |
| layer 모듈 | `com.poppang.<layer>` | `com.poppang.core` |
| feature | `com.poppang.features.<name>` | `com.poppang.features.maintab` |
| feature demo | `com.poppang.demo.<name>` | `com.poppang.demo.calendar` |
| test | `<모듈 bundle id>.tests` | `com.poppang.features.maintab.tests` |

의존성 선언:

- 다른 프로젝트 모듈은 `.project(target: "Domain", path: "../../Domain")`처럼 상대 경로로 쓴다.
- 같은 project 안의 타깃은 `.target(name: "HomeFeatureV2")`로 쓴다.
- `.external(name:)`은 `ThirdParty`와 `ADKit`에서만 쓴다.
- React Native는 `.package(product:)`와 `packages: [.local(path: "../../Vendor/PrebuiltReactNativeFrameworks")]`로 연결한다.

scheme:

- 명시적 scheme은 `Core`, `Data`, `AlertFeatureDemo`에만 있다. 나머지는 Tuist가 자동으로 만든다.
- 테스트를 CI에서 돌리려면 test action이 있는 scheme이 필요하다. ([테스트](../development/testing.md))

Swift 설정:

- manifest에 `SWIFT_VERSION`, `SWIFT_STRICT_CONCURRENCY` 설정이 없다. Tuist와 Xcode 기본값을 쓴다.
- `MainTabFeature`만 `SWIFT_UPCOMING_FEATURE_INFER_SENDABLE_FROM_CAPTURES = YES`를 켠다.
- Swift 언어 모드나 concurrency 설정을 바꾸는 것은 모듈 설정 변경이므로 계획에 적고 승인을 받는다.

feature 모듈의 실제 모양(`Projects/Features/HomeFeatureV2/Project.swift`를 줄인 것):

```swift
let project = Project(
    name: "HomeFeatureV2",
    targets: [
        .target(
            name: "HomeFeatureV2",
            destinations: [.iPhone],
            product: .staticFramework,
            bundleId: "com.poppang.features.home.v2",
            deploymentTargets: .iOS("17.0"),
            infoPlist: .default,
            sources: ["Sources/**"],
            dependencies: [
                .project(target: "ADKit", path: "../../Shared/ADKit"),
                .project(target: "Domain", path: "../../Domain"),
                .project(target: "DSKit", path: "../../Shared/DSKit"),
                .project(target: "Core", path: "../../Shared/Core"),
                .project(target: "ThirdParty", path: "../../Shared/ThirdParty"),
            ]
        ),
        .target(name: "HomeFeatureV2Demo", product: .app, sources: ["Demo/Sources/**"], ...),
        .target(name: "HomeFeatureV2Tests", product: .unitTests, sources: ["Tests/**"], ...),
    ]
)
```

## 새 모듈 만들기

### Feature 모듈

```bash
make module LAYER=feature NAME=Notice
```

`Tuist/Templates/feature-module`이 아래 파일을 만든다.

```text
Projects/Features/NoticeFeature/
├── Project.swift                              NoticeFeature(staticFramework), NoticeFeatureDemo(app)
├── Interface/Sources/NoticeFeatureEntryView.swift   INTERFACE 값과 관계없이 항상 생성
├── Sources/Presentation/NoticeFeatureView.swift
└── Demo/Sources/NoticeFeatureDemoApp.swift
```

템플릿 결과는 현재 feature 모듈 모양과 다르다. 생성한 뒤 아래를 맞춘다.

- [ ] 템플릿은 `ThirdParty`만 의존한다. 필요한 `Domain`, `Core`, `DSKit`(광고가 있으면 `ADKit`)을 추가한다.
- [ ] `Interface`를 쓰지 않으면 `Interface/` 폴더를 지운다. 현재 앱에서 Interface 타깃을 쓰는 feature는 없다.
- [ ] reducer 로직이 있으면 `<Name>FeatureTests` 타깃을 추가한다. 템플릿에는 Tests 타깃이 없다.
- [ ] reducer(`<Name>Feature.swift`)와 client(`Sources/Dependency/<Name>Client.swift`)를 [TCA Feature 작성 규칙](tca-feature.md)과 [의존성 주입](dependency-injection.md)에 맞춰 추가한다.
- [ ] parent(`MainTabFeature` 등)의 `Project.swift`에 `.project(target:path:)`를 추가하고, `MainTabFeatureDependencies`에서 client를 조립한다.
- [ ] [아키텍처](architecture.md#모듈-지도)의 모듈 지도와 의존성 표를 고친다.

### 다른 layer

`make module`의 다른 layer 템플릿은 지금 저장소 구조와 맞지 않는 경로에 파일을 만든다. 사용하지 않는다(`확인 필요`: 템플릿 수정은 별도 작업).

| layer | 템플릿이 만드는 위치 | 실제 구조 |
| --- | --- | --- |
| `core`, `dskit`, `thirdparty` | `Projects/Core/<N>`, `Projects/DSKit/<N>`, `Projects/ThirdParty/<N>SDK` | `Projects/Shared/*` 아래 단일 모듈. 템플릿 경로는 `Workspace.swift`에 포함되지도 않는다. |
| `domain`, `data` | `Projects/Domain/<N>Domain`, `Projects/Data/<N>Data` (하위 project) | 단일 `Domain`, `Data` project |
| `app`, `shared` | `Projects/App/<N>`, `Projects/Shared/<N>` | `App`은 단일 project. `Shared`는 새 공유 모듈일 때만 검토한다. |

Domain·Data·Shared 기능은 기존 모듈 안에 파일을 추가한다. 새 공유 모듈이 정말 필요하면 기존 `Shared/*/Project.swift`를 참고해 직접 만들고, 의존성 방향과 product type을 계획에 적는다.

## 외부 패키지

`Tuist/Package.swift`에서 모든 패키지를 `exact`로 고정한다.

| 패키지 | 버전 |
| --- | --- |
| firebase-ios-sdk | 12.6.0 |
| swift-package-manager-google-mobile-ads | 13.4.0 |
| GoogleSignIn-iOS | 9.0.0 |
| kakao-ios-sdk | 2.26.0 |
| Kingfisher | 8.6.2 |
| Moya | 15.0.3 |
| SPM-NMapsMap | 3.23.2 |
| swift-composable-architecture | 1.26.2 (Xcode 27 지원은 1.26.0부터) |
| indextrown/Listkit | 1.0.5 (`HomeFeature`만 사용) |
| PopPangListKit | 1.1.0 |
| BottomSheet | 3.1.1 |

product type override 원칙(`Tuist/Package.swift` 주석 기준):

- 기본은 override하지 않는다. 목록에 없는 product는 `.staticFramework`로 통합된다.
- `no such module`, explicit module 실패, 링크 실패가 실제로 재현될 때만 문제 product와 그 product가 직접 기대하는 하위 product까지 좁게 override한다.
- 현재 `.framework`로 고정한 product: Alamofire, Moya, GoogleSignIn과 전이 product(AppAuth, AppCheckCore, GTM*, GoogleUtilities-*, GUL*, FBLPromises), KakaoSDK(Auth, Common, Share, Template, User), BottomSheet, Kingfisher, GoogleMobileAds, third-party-IsAppEncrypted
- Firebase는 override하지 않는다. `.framework`로 강제하면 auto-link 링크 에러가 재현됐다.
- App은 `FirebaseCore`(`0. AppSDKInitializer.swift`), `FirebaseMessaging`(`AppNotificationManager.swift`), `FirebaseAnalytics`(`FirebaseLogger.swift`)를 직접 import한다.

패키지를 추가·업데이트하면 `Tuist/Package.resolved`가 바뀐다. 버전 변경은 의존성 변경이므로 계획에 적고 승인을 받는다.

## ThirdParty 허브

- 외부 SDK product는 `Projects/Shared/ThirdParty/Project.swift`의 `.external(name:)`으로 모은다.
- 다른 모듈은 `ThirdParty`에 의존하고, SDK가 필요한 파일에서 실제 모듈(`import Moya`, `import Kingfisher`, `import PopPangListKit` 등)을 import한다.
- `ThirdParty`는 `@_exported import`로 SDK를 다시 노출하지 않는다.
- 예외로 `ADKit`은 `GoogleMobileAds`를 직접 링크하고 초기화한다.

## 생성물과 정리되지 않은 파일

- `*.xcodeproj`, `PopPang.xcworkspace`, `**/Derived/`, `.tuist/`, `Tuist/.build/`는 생성물이다. 직접 고치거나 커밋하지 않는다.
- 아래 파일은 역할이 없거나 오래된 상태다. 지우거나 고치기 전에 사용자에게 확인한다.

| 파일 | 상태 |
| --- | --- |
| 루트 `Domain` (빈 파일) | 커밋되어 있지만 쓰이지 않는다. |
| 루트 `.package.resolved` | DifferenceKit만 고정되어 있다. 패키지 버전의 기준은 `Tuist/Package.resolved`다. |
| `Projects/Domain/Sources/Dependency/DIContainer.swift` | 생성된 project graph가 경로를 참조해서 남긴 빈 placeholder다. |
| `Projects/Features/PopupDetailFeature/Interface/`, `Projects/Features/SearchFeature/Interface/` | 어떤 타깃에도 속하지 않는 템플릿 잔여물이다. |

## 관련 문서

- [아키텍처](architecture.md)
- [Tuist 설치와 실행](../development/tuist.md)
