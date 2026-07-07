<div align=center>

# PopPang
### **팝업스토어 키워드 알리미**
팝업에 관심은 있지만 매번 검색하기 번거롭나요?  
PopPang은 관심있는 팝업 정보를 놓치지 않도록, 실시간으로 전해드립니다.  
<br/><br/>

<div align="center">
  <img src="https://github.com/user-attachments/assets/49436331-9850-4319-b9fd-c1302d8c9375" width="100%" />
</div>

</div>
<br/><br/>

# 1. 기능 소개

1. 키워드를 등록해 원하는 팝업 알림 받기
2. 검색·필터로 보고 싶은 팝업 바로 찾기
3. 달력에서 날짜별 팝업 일정 확인하기
4. 지도로 내 주변 팝업 한눈에 보기
5. 관심 팝업을 찜해 나만의 리스트로 관리하기
6. 상세 정보, 공유, 외부 링크, 리뷰 흐름까지 한 번에 이용하기

<br/><br/>

# 2. 기술 스택

| library | description |
|:---:|:---:|
| **Tuist** | Micro Feature Architecture 기반 workspace와 project를 구성하기 위함 |
| **Compound** | Feature 단위 MVI 상태 관리를 구현하기 위함 |
| **FirebaseSDK** | FCM 푸시 알림과 Analytics를 구현하기 위함 |
| **KakaoSDK** | 카카오 소셜 로그인과 카카오 공유를 구현하기 위함 |
| **GoogleSignIn** | 구글 소셜 로그인을 구현하기 위함 |
| **Moya** | 추상화된 네트워크 레이어를 보다 간편하게 사용하기 위함 |
| **Kingfisher** | 이미지 캐싱 처리 및 UI 성능 개선을 위함 |
| **NMapsMap** | 지도 기반 팝업 탐색 기능을 구현하기 위함 |
| **BottomSheet** | 지도와 상세 흐름의 바텀시트 UI를 구현하기 위함 |

<br/><br/>

# 3. 모듈 의존성 그래프

<div align="center">
  <img src="./Docs/images/module-dependency-graph.png" width="100%" />
</div>

<br/><br/>

# 4. 코디네이터 트리

<div align="center">
  <img src="./CoordinatorTree.png" width="100%" />
</div>

<br/><br/>

# 5. 핵심 성과

### **1. 로딩 지연 문제 개선**
> **문제**  
> 여러 API가 순차적으로 호출되며 전체 로딩이 길어졌음  
>
> **해결**  
> `TaskGroup`을 활용해 병렬 처리 구조로 전환  
>
> **성과**  
> 🔸 **초기 로딩 시간 40% 단축**

```swift
func getAllPopupData() async {
    do {
        try await withThrowingTaskGroup(of: (Int, [Popup]).self) { group in
            group.addTask { (0, await self.getPersonalRandomPopupList()) }
            group.addTask { (1, await self.getPersonalUpcomingPopupList()) }
            group.addTask { (2, await self.getPersonalFilteredPopupList()) }

            for try await (index, popups) in group {
                await MainActor.run {
                    switch index {
                    case 0: self.bestPopups = popups
                    case 1: self.comingPopups = popups
                    case 2: self.gridPopups = popups
                    default: break
                    }
                }
            }
        }
    } catch {
        Logger.e("❌ 로딩 실패: \(error)")
    }
}
```

---

### **2. Moya를 async/await으로 사용하기 위한 공통 async 래퍼 생성**
> **문제**  
> Moya는 completion 기반이라 async/await과 직접 호환되지 않아  
> API마다 동일한 변환 코드가 반복됨  
>
> **해결**  
> `withCheckedThrowingContinuation` 기반 **공통 async 변환 래퍼** 구현  
>
> **성과**  
> 🔸 Repository 전역에서 동일한 async 인터페이스 사용  
> 🔸 **중복 코드 감소 + 유지보수성 향상**

```swift
extension MoyaProvider {
    func asyncRequest(_ target: Target) async throws -> Response {
        try await withCheckedThrowingContinuation { continuation in
            self.request(target) { result in
                switch result {
                case .success(let response):
                    continuation.resume(returning: response)
                case .failure(let error):
                    continuation.resume(throwing: error)
                }
            }
        }
    }
}

let response = try await provider.asyncRequest(.getPopupList)
```

---

### **3. 화면 이동 로직을 통일해 일관성 있는 네비게이션 확보**
> **문제**  
> push / sheet / overlay 화면 전환 코드가 각 View에 흩어져 있어  
> 네비게이션 흐름이 일관적이지 않고 유지보수가 어려웠음  
>
> **해결**  
> Route 기반 **Generic Coordinator** 도입으로  
> 모든 화면 이동을 **동일한 호출 형태**로 사용하도록 개선  
>
> **성과**  
> 🔸 push / sheet / overlay를 **하나의 패턴으로 호출**  
> 🔸 화면이동 관련 상태 변수 70% 감소  
> 🔸 **일관된 네비게이션 흐름 확보 및 View 코드 간결화**

```swift
class Coordinator<R: Hashable, S: Identifiable, O: Identifiable>: ObservableObject {
    @Published var paths: [R] = []
    @Published var sheet: S?
    @Published var overlay: O?

    func push(_ route: R) {
        paths.append(route)
    }

    func present(_ sheet: S) {
        self.sheet = sheet
    }

    func showOverlay(_ overlay: O) {
        self.overlay = overlay
    }
}

coordinator.push(.detail(popup))
coordinator.present(.regionSheet)
coordinator.showOverlay(.notification)
```

---

### **4. CSV 기반 로컬라이제이션 자동화로 다국어 관리 비용 절감**
> **문제**  
> `Localizable.strings`를 언어별로 직접 관리하면  
> 키 누락, 오타, 언어별 불일치가 생기기 쉽고 문자열 키를 하드코딩할 때 디버깅 비용도 커졌음  
>
> **해결**  
> `Python/localizable.csv`를 기준으로  
> `en/ko/ja Localizable.strings`와 `LocalizationKeys.swift`를 자동 생성하는  
> CSV 기반 로컬라이제이션 생성 스크립트 구축  
>
> **성과**  
> 🔸 번역 데이터를 CSV 한 곳에서 일괄 관리  
> 🔸 `LocalizationKey` enum 자동 생성으로 문자열 오타 위험 감소  
> 🔸 번역 작업자, 기획자, 개발자가 같은 포맷으로 협업 가능

```swift
Text(LocalizationKey.commonNext.localized(comment: "Next button"))
```

---

### **5. 단일 타깃 구조를 Tuist 기반 Micro Feature Architecture로 전환**
> **문제**  
> 기존 `V0` 앱은 `App`, `Presentation`, `Util`, `DesignSystem`이 단일 타깃에 섞여 있어  
> 기능이 늘어날수록 변경 영향 범위가 커지고, 독립 개발과 빌드 검증이 어려웠음  
>
> **해결**  
> `App / Coordinator / Features / Domain / Data / Shared` 구조로 분리하고,  
> `Tuist` 템플릿과 `Makefile` 래퍼로 feature, domain, data, core 모듈을 일관되게 생성하도록 구성  
>
> **성과**  
> 🔸 기능별 독립 모듈 개발 기반 확보  
> 🔸 App 조립, 화면 흐름, UI 기능, 도메인 규칙, 데이터 구현 책임 분리  
> 🔸 Demo app과 Core/Data 테스트를 통한 모듈 단위 검증 기반 확보  
> 🔸 클린빌드 평균 **129.447초 → 46.884초**로 개선, 모듈화 프로젝트가 약 **2.76배 빠름**  
> 🔸 증분빌드 평균 **6.415초 → 4.184초**로 개선, 모듈화 프로젝트가 약 **1.53배 빠름**

| 구분 | V0 | 모듈화 프로젝트 | 차이 |
|:---:|:---:|:---:|:---:|
| 클린빌드 평균 | 129.447초 | 46.884초 | 모듈화가 약 2.76배 빠름 |
| 증분빌드 평균 | 6.415초 | 4.184초 | 모듈화가 약 1.53배 빠름 |

| 측정 조건 | 값 |
|:---:|:---:|
| 반복 횟수 | 5회 |
| Destination | `generic/platform=iOS Simulator` |
| Configuration | `Debug` |
| V0 기준 | `V0/PopPang.xcodeproj`, scheme `PopPang` |
| 모듈화 기준 | `PopPang.xcworkspace`, scheme `PopPangApp` |
| 증분빌드 기준 | 파일 수정 없는 no-op 증분빌드 |

```text
Projects
├── App
├── Coordinator
├── Features
│   ├── AuthFeature
│   ├── OnboardingFeature
│   ├── HomeFeature
│   ├── SearchFeature
│   ├── PopupDetailFeature
│   ├── MapFeature
│   ├── CalendarFeature
│   ├── FavoritesFeature
│   ├── ProfileFeature
│   ├── AlertFeature
│   └── ReviewFeature
├── Domain
├── Data
└── Shared
    ├── Core
    ├── DSKit
    └── ThirdParty
```

---

### **6. 외부 SDK 의존성을 ThirdParty 링크 허브로 추적 가능하게 정리**
> **문제**  
> 외부 SDK가 여러 레이어에 직접 흩어지면 어떤 모듈이 어떤 SDK product를 링크하는지 파악하기 어렵고,  
> SPM product type 문제로 빌드와 런타임 경고가 발생할 수 있었음  
>
> **해결**  
> 외부 SDK product는 `Projects/Shared/ThirdParty`에서만 `.external(...)`로 링크하고,  
> 실제 SDK 타입을 사용하는 파일은 `import Moya`, `import Kingfisher`, `import KakaoSDKShare`, `import NMapsMap`처럼 실제 모듈명을 명시  
>
> **성과**  
> 🔸 SDK 링크 지점 단일화  
> 🔸 `@_exported` 재노출 없이 실제 SDK 사용처 추적 가능  
> 🔸 Firebase, GoogleSignIn, KakaoSDK, Moya 등 product type 정책을 `Tuist/Package.swift`에서 관리

```swift
.target(
    name: "ThirdParty",
    product: .framework,
    dependencies: [
        .external(name: "FirebaseAnalytics"),
        .external(name: "FirebaseMessaging"),
        .external(name: "GoogleSignIn"),
        .external(name: "KakaoSDKUser"),
        .external(name: "Kingfisher"),
        .external(name: "Moya"),
        .external(name: "NMapsMap"),
    ]
)
```

<br/><br/>

# 6. 실행 방법

Tuist 버전은 `4.115.0`으로 고정합니다.

```bash
tuist version
tuist install
tuist generate
```

생성된 workspace를 정리 후 다시 만들 때는 아래 명령을 사용합니다.

```bash
make regen
```

빌드는 아래 명령으로 확인합니다.

```bash
tuist build PopPangApp
tuist build Coordinator
```

Core/Data 테스트는 아래 명령으로 실행합니다.

```bash
tuist test Core
tuist test Data
```

<br/><br/>

# 7. 모듈 생성 명령

```bash
make module LAYER=feature NAME=Home
make module LAYER=feature NAME=PopupDetail INTERFACE=true
make module LAYER=domain NAME=Popup
make module LAYER=data NAME=Popup
make module LAYER=core NAME=HTTPClient
make module LAYER=dskit NAME=DSKit
make module LAYER=shared NAME=UIComponents
```

<br/><br/>

# 8. 참고

- `AGENTS.md`: 저장소 작업 규칙과 아키텍처 기준
- `Projects/Coordinator/README.md`: Coordinator 상세 가이드
- `V0/README.md`: 기존 단일 타깃 앱 README
- `Tuist/Package.swift`: 외부 의존성과 product type 정책
