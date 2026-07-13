# Static / Dynamic Linking Guide

이 문서는 PopPang의 Tuist 모듈에서 `.staticFramework`와 `.framework`를 언제 쓰는지 정리한다.

핵심 결론:

- 앱 내부 전용 feature는 기본적으로 `.staticFramework`를 쓴다.
- 외부 SDK를 모으는 `ThirdParty`, 여러 상위 모듈이 직접 import하는 기반 모듈, 실제로 dynamic이 필요한 SPM product는 `.framework`를 쓴다.
- `import` 중복과 링크 중복은 다른 문제다. Swift 파일에서 같은 SDK를 여러 번 `import`하는 것 자체가 문제는 아니다.
- 문제는 같은 SDK 코드가 여러 dynamic framework 바이너리에 각각 포함될 때 생긴다.
- feature를 static으로 두는 이유는 feature framework 수를 런타임에 늘리지 않기 위해서다.
- 외부 SDK 중복 포함 문제는 feature static만으로 해결하지 않고, `ThirdParty` 허브와 `Tuist/Package.swift`의 `PackageSettings.productTypes`로 제어한다.

## 용어

### `import`

Swift 소스가 어떤 module의 public API를 컴파일 시점에 볼 수 있게 하는 문법이다.

예:

```swift
import Kingfisher
import KakaoSDKShare
```

`import`는 "이 파일이 저 모듈 타입을 안다"는 뜻이지, 곧바로 "앱 번들에 같은 라이브러리가 여러 개 들어간다"는 뜻은 아니다.

중복 `import` 자체는 보통 문제가 아니다.

문제는 아래 단계에서 생긴다.

### link

컴파일된 코드가 실제 함수, 타입, 심볼을 어디서 가져올지 연결하는 단계다.

예:

- `PopupDetailFeature`가 `KakaoSDKShare` 타입을 사용한다.
- linker는 `KakaoSDKShare` 구현이 어느 바이너리에 있는지 찾아 연결한다.
- static이면 그 구현 코드가 상위 바이너리에 합쳐질 수 있다.
- dynamic이면 별도 `.framework`를 참조하고 런타임에 로드한다.

### embed

dynamic framework를 앱 번들 안의 `Frameworks/` 같은 위치에 넣는 단계다.

static framework는 최종 바이너리에 합쳐지므로 앱 번들에 별도 framework로 embed되지 않는 것이 기본 개념이다.

### dyld load

앱 실행 시 iOS dynamic loader가 앱 실행 파일과 dynamic framework들을 읽고 연결하는 단계다.

dynamic framework가 많을수록 앱 시작 시 로드해야 하는 파일과 심볼 연결 작업이 늘어난다.

## Tuist product type

### `.staticFramework`

framework 형태의 산출물이지만, 실제 코드는 링크 시점에 상위 바이너리로 합쳐진다.

특징:

- 앱 실행 시 별도로 로드할 framework 수가 줄어든다.
- 앱 내부 leaf 모듈에 적합하다.
- feature가 많아져도 런타임 dynamic framework 개수를 늘리지 않는다.
- 런치 성능과 앱 번들 단순성에 유리하다.
- 상위 타깃이 다시 링크되어야 하므로 일부 증분 빌드에서는 dynamic보다 불리할 수 있다.
- 같은 static dependency를 여러 dynamic framework가 각각 링크하면 코드 중복이 생길 수 있다.

### `.framework`

Tuist에서 일반적으로 dynamic framework를 의미한다.

특징:

- 앱 실행 시 별도 framework로 로드된다.
- 바이너리 경계가 명확하다.
- 특정 모듈만 교체/분리/배포해야 하는 경우 적합하다.
- 여러 상위 산출물이 같은 dynamic framework 하나를 참조하게 만들 수 있다.
- 앱 시작 시 dyld가 로드할 framework 수가 늘어난다.
- embed/sign 설정이 필요하다.
- 외부 SDK가 기대한 링크 방식과 다르면 `no such module`, undefined symbols, duplicate class 문제가 생길 수 있다.

## 빌드 단계별로 보는 차이

### static feature

예: `HomeFeature.product = .staticFramework`

개념 흐름:

```text
HomeFeature sources
 -> HomeFeature static framework
 -> Coordinator.framework 또는 App에 링크 시 코드가 합쳐짐
 -> 앱 실행 시 HomeFeature.framework를 별도로 로드하지 않음
```

실행 시점 관점:

- `HomeFeature` 자체는 별도 dynamic framework로 로드되지 않는다.
- `HomeFeature`가 쓰는 `DSKit.framework`, `Core.framework`, `ThirdParty.framework` 같은 dynamic 의존성은 별도로 로드될 수 있다.
- 즉 feature만 static이라고 해서 모든 의존성이 static이 되는 것은 아니다.

### dynamic module

예: `Data.product = .framework`

개념 흐름:

```text
Data sources
 -> Data.framework
 -> App bundle에 embed
 -> 앱 실행 시 dyld가 Data.framework 로드
```

실행 시점 관점:

- `Data.framework`가 앱 번들에 별도 파일로 존재한다.
- 앱 시작 또는 해당 framework 로드 시점에 dyld 비용이 든다.
- `Data.framework` 안에 static SDK 코드가 합쳐져 있으면 다른 dynamic framework와 중복될 수 있다.

## PopPang 현재 정책

### 현재 target product type

| 영역 | 현재 product | 이유 |
| --- | --- | --- |
| `Projects/Features/*Feature` | `.staticFramework` | 앱 내부 전용 leaf feature. feature 수가 많으므로 런타임 dynamic framework 증가를 막는다. |
| `SearchFeatureInterface`, `PopupDetailFeatureInterface` | `.framework` | 다른 모듈이 명시적으로 import하는 재사용 경계다. |
| `Domain` | `.framework` | Feature/Data/App이 공유하는 계약 경계다. |
| `Data` | `.framework` | repository 구현과 외부 SDK 로그인 구현이 있는 인프라 경계다. |
| `Core` | `.framework` | 네트워크, 저장소, formatter 등 여러 레이어가 공유하는 기반 모듈이다. |
| `DSKit` | `.framework` | Feature들이 공유하는 UI resource/API 경계다. |
| `ThirdParty` | `.framework` | 외부 SDK product를 한 곳에서 링크하는 허브다. |
| `PopPangRNFeature` | `.framework` | RN prebuilt static binary를 하나의 동적 경계에서 링크해 Host와 generated provider 심볼을 최종 앱에 한 번만 전달한다. |
| demo app | `.app` | 독립 실행 샘플 앱이다. |
| App | `.app` | 최종 앱 산출물이다. |

RN prebuilt 산출물은 저장소에 커밋하지 않고 `scripts/download-rn-release.sh`로 `Vendor/PrebuiltReactNativeFrameworks`와 `Projects/App/Resources/ReactNative`에 내려받는 것을 기본값으로 둔다.

### feature는 왜 static인가

PopPang feature는 아래 성격이다.

- App 내부에서만 사용한다.
- 외부 배포용 SDK가 아니다.
- 런타임에 feature 바이너리를 교체하지 않는다.
- feature 간 직접 import를 줄이고 parent TCA reducer의 `Path`/`Destination`에서 조립한다.
- feature 수가 많다.
- 대부분 UI와 feature state를 가진 leaf 모듈이다.

그래서 feature를 dynamic으로 만들면 이득보다 비용이 커진다.

예외:

- `PopPangRNFeature`는 React Native prebuilt static binary의 linker settings를 보존해야 하므로 `.framework`를 사용한다. App과 `MainTabFeature`는 RN package를 직접 의존하지 않는다.

dynamic feature의 비용:

- `HomeFeature.framework`, `MapFeature.framework`, `ProfileFeature.framework`처럼 앱 번들 framework 수가 늘어난다.
- dyld가 앱 시작 시 더 많은 framework를 검토해야 한다.
- embed/sign 대상이 늘어난다.
- 외부 SDK를 직접 쓰는 feature가 늘면 SDK 중복 포함 위험 표면도 커진다.
- 앱 내부 전용 코드인데 런타임 바이너리 경계를 유지하는 비용을 계속 낸다.

static feature의 이점:

- feature 모듈 경계는 유지하면서 런타임 framework 수는 줄인다.
- 앱 시작 비용이 낮아질 가능성이 높다.
- feature 자체를 embed/sign하지 않아도 된다.
- App 입장에서는 feature 코드를 최종 산출물에 합쳐서 단순하게 실행할 수 있다.

## ThirdParty와 feature static의 관계

중요한 점:

feature를 static으로 둔다고 외부 SDK 중복 문제가 자동으로 사라지는 것은 아니다.

예:

```text
Data.framework
 -> import KakaoSDKAuth

PopupDetailFeature.staticFramework
 -> import KakaoSDKShare
 -> Coordinator.framework에 합쳐짐
```

만약 Kakao SDK product가 static으로 처리되면 이런 일이 생길 수 있다.

```text
Data.framework 안에 KakaoSDKCommon 코드 포함
Coordinator.framework 안에도 KakaoSDKCommon 코드 포함
앱 실행 시 같은 KakaoSDKCommon class가 두 framework에서 로드됨
duplicate class 경고 발생
```

그래서 PopPang은 두 가지를 같이 한다.

1. 외부 SDK `.external(...)` 선언은 `ThirdParty` 타깃에만 둔다.
2. 중복 또는 링크 문제가 실제로 난 SDK product는 `Tuist/Package.swift`에서 `.framework`로 고정한다.

즉 역할이 다르다.

| 장치 | 해결하는 문제 |
| --- | --- |
| feature `.staticFramework` | feature 자체가 dynamic framework로 많이 늘어나는 문제를 줄인다. |
| `ThirdParty` 허브 | 외부 SDK 선언 위치를 한 곳으로 모은다. |
| `PackageSettings.productTypes` | 특정 외부 SDK를 static/dynamic 중 어떤 방식으로 링크할지 강제한다. |

## 언제 `.staticFramework`를 쓰는가

아래 조건이 많을수록 static이 맞다.

### 1. 앱 내부 전용 모듈이다

예:

- `HomeFeature`
- `SearchFeature`
- `CalendarFeature`
- `FavoritesFeature`
- `AlertFeature`
- `ReviewFeature`

이 모듈들은 App 밖에서 독립 SDK처럼 배포하지 않는다.

권장:

```swift
product: .staticFramework
```

### 2. leaf feature다

leaf feature는 보통 아래쪽에 위치한다.

```text
App
 -> Coordinator
   -> Feature
      -> Domain/Core/DSKit/ThirdParty
```

다른 많은 모듈이 이 feature를 다시 의존하지 않는다.

이런 경우 dynamic으로 분리할 이유가 약하다.

### 3. feature 수가 많다

feature가 10개라면 dynamic feature도 10개 생긴다.

앱 실행 시 dynamic loader는 더 많은 framework를 확인해야 한다.

앱 내부 feature가 많을수록 static이 유리해지는 경우가 많다.

### 4. 런타임 경계보다 실행 단순성이 중요하다

feature를 런타임에 별도 로드하거나 교체하지 않는다면 dynamic boundary는 비용이다.

PopPang은 feature toggle로 바이너리를 갈아끼우는 앱이 아니다.

따라서 static이 더 단순하다.

### 5. 외부 SDK 직접 노출 경계를 feature에 두고 싶지 않다

feature가 SDK를 직접 import하더라도 `.external(...)` 선언은 `ThirdParty`에 모은다.

feature 자체를 dynamic으로 만들면 feature framework 안에 SDK 링크 흔적이 더 강하게 남는다.

static feature는 최종 조립 단계로 합쳐지므로 앱 내부 구현 디테일에 가깝게 다룰 수 있다.

## 언제 `.framework`를 쓰는가

아래 조건이 많을수록 dynamic framework가 맞다.

### 1. 여러 모듈이 공유하는 명확한 경계다

예:

- `Domain`
- `Core`
- `DSKit`
- `ThirdParty`

이들은 여러 feature와 Data/Coordinator가 공유한다.

dynamic으로 두면 조립 경계가 명확하고, import 관계가 추적하기 쉽다.

### 2. 외부 SDK 허브다

`ThirdParty`는 외부 SDK product 선언을 모으는 허브다.

권장:

```swift
product: .framework
```

이유:

- 외부 SDK 링크 지점을 한 곳으로 모은다.
- App/Data/Feature/Coordinator가 SDK `.external(...)`을 직접 반복 선언하지 않게 한다.
- 어떤 SDK product를 dynamic으로 둘지 `PackageSettings.productTypes`와 함께 관리한다.

### 3. 특정 SPM product가 dynamic이어야 링크가 안정적이다

PopPang 실제 사례:

- `Moya`가 `Alamofire`를 못 찾는 문제가 있었다.
- 그래서 `Moya`, `Alamofire`를 `.framework`로 고정했다.

```swift
"Alamofire": .framework,
"Moya": .framework,
```

### 4. 특정 SDK가 static이면 duplicate class가 난다

PopPang 실제 사례:

- `Data`는 Kakao login SDK를 쓴다.
- `PopupDetailFeature`는 Kakao share SDK를 쓴다.
- feature static 산출물은 `Coordinator.framework`에 합쳐진다.
- Kakao product가 static이면 `KakaoSDKCommon`이 `Data.framework`와 `Coordinator.framework` 양쪽에 들어갈 수 있다.
- 런타임 duplicate class 경고가 난다.

해결:

```swift
"KakaoSDKAuth": .framework,
"KakaoSDKCommon": .framework,
"KakaoSDKShare": .framework,
"KakaoSDKTemplate": .framework,
"KakaoSDKUser": .framework,
```

### 5. 앱과 extension이 같은 바이너리 산출물을 공유해야 한다

현재 PopPang의 주요 기준은 아니지만, 일반적으로 앱과 extension이 같은 큰 구현체를 각각 static으로 링크하면 중복이 커질 수 있다.

이때 별도 dynamic framework로 공유하는 선택지를 검토할 수 있다.

단, iOS extension embedding, App Store 정책, extension-safe API 여부를 같이 봐야 한다.

## 언제 `.framework`를 쓰면 안 좋은가

### 1. 모든 feature를 dynamic으로 만드는 경우

나쁜 기본값:

```text
HomeFeature.framework
SearchFeature.framework
PopupDetailFeature.framework
MapFeature.framework
CalendarFeature.framework
FavoritesFeature.framework
ProfileFeature.framework
AlertFeature.framework
ReviewFeature.framework
AuthFeature.framework
OnboardingFeature.framework
```

문제:

- 앱 번들 framework 수가 많아진다.
- embed/sign 시간이 늘어난다.
- 런치 시 dyld 작업이 늘어난다.
- feature가 외부 SDK를 import할 때 중복 링크 문제가 더 잘 보인다.
- 앱 내부 전용 feature인데 runtime binary boundary 비용을 낸다.

### 2. Firebase 계열을 무리하게 dynamic으로 강제하는 경우

Firebase는 SPM 배포가 static 쪽에 강하게 맞춰져 있다.

PopPang에서도 Firebase/Google 계열 product를 무리하게 `.framework`로 강제했을 때 `swiftCompatibility*`, `UIUtilities`, `SwiftUICore` auto-link 문제가 재현됐다.

따라서 Firebase는 기본 product type을 깨지 않는 것을 우선한다.

### 3. 근거 없이 SPM product override를 많이 추가하는 경우

`Tuist/Package.swift`의 `productTypes`는 문제 해결용이다.

원칙:

- 기본은 override하지 않는다.
- 실제 오류가 난 product만 좁게 override한다.
- 그 product가 직접 필요로 하는 전이 product까지만 추가한다.
- "혹시 모르니까 전부 `.framework`"는 피한다.

## 언제 `.staticFramework`를 쓰면 안 좋은가

### 1. 같은 static 코드가 여러 dynamic framework에 중복 포함되는 경우

예:

```text
Data.framework
 -> StaticSDK 포함

Coordinator.framework
 -> Feature.staticFramework 포함
 -> StaticSDK 포함
```

이 경우 앱 실행 시:

```text
Data.framework에도 StaticSDK class 존재
Coordinator.framework에도 StaticSDK class 존재
```

ObjC/Swift runtime class가 중복 등록될 수 있다.

KakaoSDKCommon duplicate class가 이 유형이다.

해결은 feature를 dynamic으로 바꾸는 것이 아니라, 보통 문제 SDK product를 `.framework`로 고정해서 한 번만 로드되게 만드는 것이다.

### 2. 모듈을 외부에 binary SDK처럼 배포해야 하는 경우

외부 배포용이면 소비자가 그 framework를 별도 binary로 받아야 할 수 있다.

그때는 `.framework`가 더 자연스럽다.

### 3. 자주 수정하는 큰 기반 모듈이 상위 타깃 재링크를 과하게 유발하는 경우

static은 상위 바이너리에 합쳐진다.

큰 모듈을 자주 수정하면 상위 타깃 재링크 비용이 커질 수 있다.

이때는 dynamic이 증분 빌드에 유리할 수 있다.

## PopPang 의사결정표

새 모듈을 만들 때 아래 순서로 판단한다.

| 질문 | 예 | 선택 |
| --- | --- | --- |
| App 최종 산출물인가? | `PopPangApp` | `.app` |
| 독립 실행 demo인가? | `HomeFeatureDemo` | `.app` |
| 앱 내부 feature인가? | `HomeFeature`, `MapFeature` | `.staticFramework` |
| feature의 재사용 public entry interface인가? | `SearchFeatureInterface` | `.framework` |
| 여러 레이어가 공유하는 계약/기반 모듈인가? | `Domain`, `Core`, `DSKit` | `.framework` |
| repository 구현/SDK adapter가 있는 Data 경계인가? | `Data` | `.framework` |
| 외부 SDK product 허브인가? | `ThirdParty` | `.framework` |
| SPM product가 static 기본값으로 링크 오류를 내는가? | `Moya`, `Alamofire` | `PackageSettings`에서 `.framework` |
| SPM product가 dynamic 강제 시 링크 오류를 내는가? | Firebase 계열 | override하지 않음 |
| SPM product가 static이면 duplicate class가 나는가? | KakaoSDKCommon, BottomSheet | `PackageSettings`에서 `.framework` |

## PopPang 현재 SPM product override

`Tuist/Package.swift`의 `PackageSettings.productTypes`는 외부 패키지 product에만 적용된다.

local target의 `product: .staticFramework` 또는 `product: .framework`와는 별도 개념이다.

현재 dynamic override가 필요한 product:

| product | 이유 |
| --- | --- |
| `Alamofire` | `Moya`가 `Alamofire` 모듈을 찾지 못하는 문제 방지 |
| `Moya` | `Alamofire`와 함께 dynamic framework로 고정해야 모듈 해석이 안정적 |
| `KakaoSDKAuth` | Data 로그인 구현에서 사용 |
| `KakaoSDKUser` | Data 로그인 구현에서 사용 |
| `KakaoSDKShare` | PopupDetail share 구현에서 사용 |
| `KakaoSDKTemplate` | Kakao share template 전이 의존 |
| `KakaoSDKCommon` | Kakao product 공통 코드 중복 포함 방지 |
| `BottomSheet` | MapFeature static 산출물이 Coordinator.framework에 합쳐질 때 ThirdParty.framework와 BottomSheet 코드가 중복 포함되는 문제 방지 |
| `GoogleSignIn` | Google 로그인 구현에서 사용 |
| `AppAuth`, `AppAuthCore`, `GTMAppAuth`, `GTMSessionFetcherCore` | GoogleSignIn 전이 의존 링크 안정화 |
| `AppCheckCore`, `FBLPromises` | GoogleSignIn/AppCheck 전이 의존 링크 안정화 |
| `GoogleUtilities-*`, `GULEnvironment`, `GULUserDefaults`, `third-party-IsAppEncrypted` | Google 계열 전이 product 링크 안정화 |

Firebase 계열은 override하지 않는다.

이유:

- Firebase SPM은 static 배포 전제가 강하다.
- 무리하게 dynamic으로 강제하면 auto-link 오류가 날 수 있다.
- `FirebaseMessaging`과 `FirebaseCoreInternal`만 dynamic으로 고정하면 빌드는 통과하지만 LLDB 심볼 해석 때문에 디바이스 실행 대기가 길어질 수 있다.
- App에서는 Firebase 직접 import를 최소화하고 bridge 또는 App 조립 계층에서만 다룬다.

## 자주 헷갈리는 질문

### `import KakaoSDKShare`가 여러 파일에 있으면 중복인가?

아니다.

`import`는 컴파일러에게 module API를 보이게 하는 선언이다.

중복 문제는 같은 SDK 구현 코드가 여러 dynamic framework 안에 각각 들어갈 때 생긴다.

### feature가 static이면 `import Kingfisher`를 못 쓰나?

쓸 수 있다.

다만 target dependency가 필요하다.

PopPang은 feature가 직접 `.external(name: "Kingfisher")`를 선언하지 않고 `ThirdParty`에 의존한다.

소스에서는 실제 SDK 모듈명을 그대로 쓴다.

```swift
import Kingfisher
```

이 규칙의 목적은 SDK 사용 사실을 숨기지 않으면서 `.external(...)` 선언 위치는 한 곳으로 모으는 것이다.

### feature static이면 feature 간 import가 안 되나?

기술적으로는 가능할 수 있지만, 아키텍처상 피한다.

PopPang 원칙:

- feature는 다른 feature 구현을 직접 import하지 않는다.
- 이동은 parent TCA reducer의 `Path`/`Destination`과 feature delegate action으로 연결한다.
- 재사용 public entry가 필요한 경우에만 `FeatureInterface`를 둔다.

### static이 빌드 속도에 항상 좋은가?

항상 그렇지는 않다.

정적 링크는 상위 타깃 재링크를 유발할 수 있다.

반대로 dynamic framework는 모듈별 증분 빌드 경계가 더 명확할 수 있다.

하지만 앱 내부 feature가 많을 때는 runtime load/embed/sign 비용까지 고려해야 한다.

PopPang은 런타임 단순성과 SDK 중복 표면 축소를 우선해서 feature를 static으로 둔다.

### dynamic이 더 모듈러다운가?

아니다.

모듈러 아키텍처의 핵심은 source boundary와 dependency direction이다.

런타임 바이너리가 dynamic인지 static인지는 별도 선택이다.

즉 `.staticFramework`여도 `import`, public API, target dependency, layer boundary는 유지된다.

### static이면 리소스가 문제되지 않나?

리소스가 많은 모듈은 반드시 확인이 필요하다.

static framework는 코드가 상위 바이너리에 합쳐지지만 리소스는 별도 bundle 처리 규칙을 탄다.

PopPang feature는 현재 feature resource보다 DSKit resource와 App resource 중심이다.

새 feature에 resource를 추가한다면 아래를 확인한다.

- Tuist가 resource bundle을 생성하는지
- `Bundle.module` 또는 Tuist generated bundle 접근이 맞는지
- demo app과 real app에서 모두 리소스가 로드되는지

## 변경 전 체크리스트

local target을 `.staticFramework`에서 `.framework`로 바꾸거나 반대로 바꾸기 전에 확인한다.

- 이 모듈이 앱 내부 전용인가?
- 이 모듈을 여러 dynamic framework가 동시에 링크하는가?
- 이 모듈 안에 ObjC runtime class를 가진 SDK가 static으로 들어가는가?
- 이 모듈이 리소스를 포함하는가?
- 이 모듈을 App extension도 쓰는가?
- 이 모듈을 외부에 binary로 배포해야 하는가?
- `tuist generate`가 통과하는가?
- App 빌드가 통과하는가?
- 앱 실행 로그에 `Class ... is implemented in both ...`가 없는가?
- `no such module`, `Undefined symbols`, `explicit module` 오류가 없는가?

SPM product override를 바꾸기 전에 확인한다.

- 오류가 실제로 재현됐는가?
- 어떤 product가 직접 원인인가?
- 전이 product까지 전부 바꿀 필요가 있는가, 아니면 하나만 바꾸면 되는가?
- Firebase처럼 dynamic 강제가 더 위험한 SDK인가?
- Kakao처럼 static 기본값이 duplicate class를 만드는 SDK인가?

## PopPang 기본 규칙

새 feature:

```swift
product: .staticFramework
```

새 feature interface:

```swift
product: .framework
```

새 domain/data/core/dskit/shared/thirdparty 모듈:

```swift
product: .framework
```

새 외부 SDK:

```swift
// Projects/Shared/ThirdParty/Project.swift
.external(name: "SDKProduct")
```

그리고 `Tuist/Package.swift`의 `PackageSettings.productTypes`에는 바로 추가하지 않는다.

먼저 기본값으로 빌드해보고, 실제 문제가 생겼을 때만 최소 범위로 override한다.

## 한 줄 판단

- "앱 내부 feature인가?" -> `.staticFramework`
- "여러 레이어가 공유하는 경계인가?" -> `.framework`
- "외부 SDK 허브인가?" -> `.framework`
- "SPM product가 static이면 duplicate class가 나는가?" -> 해당 product만 `.framework`
- "SPM product가 dynamic이면 auto-link가 깨지는가?" -> override하지 않거나 static 유지
- "그냥 더 모듈러다워 보여서 dynamic으로 바꾸고 싶은가?" -> 바꾸지 않는다.
