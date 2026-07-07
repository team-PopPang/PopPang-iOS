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
1. 키워드를 등록해 원하는 팝업 알림 받기 🔔
2. 검색·필터로 보고 싶은 팝업 바로 찾기 🔎
3. 달력에서 날짜별 팝업 일정 확인하기 📅
4. 지도로 내 주변 팝업 한눈에 보기 🗺️
5. 관심 팝업을 찜해 나만의 리스트로 관리하기 ⭐

</br><br/>

# 2. 기술 스택
|library|description|
|:---:|:---:|
|**FirebaseSDK**|FCM을 이용한 푸쉬 알림을 구현하기 위함|
|**KakaoSDK**|카카오 소셜 로그인 구현을 위함|
|**GoogleSDK**|구글 소셜 로그인 구현을 위함|
|**Moya**|추상화된 네트워크 레이어를 보다 간편하게 사용하기 위함|
|**Kingfisher**|이미지 캐싱 처리 및 UI 성능 개선을 위함|

</br><br/>

# 3. 핵심 성과

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
> 🔸 Repository 전역에서 동일한 async 인터페이스 사용.   
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

// 호출 예시
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

// 호출 예시
coordinator.push(.detail(popup))        // 화면 이동
coordinator.present(.regionSheet)       // 시트
coordinator.showOverlay(.notification)  // 오버레이
```

---

### **4. CSV 기반 로컬라이제이션 자동화로 다국어 관리 비용 절감**
> **문제**  
> `Localizable.strings`를 언어별로 직접 관리하면  
> 키 누락, 오타, 언어별 불일치가 생기기 쉽고  
> 문자열 키를 하드코딩할 때 디버깅 비용도 커졌음  
>
> **해결**  
> `Python/localizable.csv`를 기준으로  
> `en/ko/ja Localizable.strings`와 `LocalizationKeys.swift`를 자동 생성하는  
> **CSV 기반 로컬라이제이션 생성 스크립트** 구축  
>
> **성과**  
> 🔸 번역 데이터를 CSV 한 곳에서 일괄 관리  
> 🔸 `LocalizationKey` enum 자동 생성으로 문자열 오타 위험 감소  
> 🔸 번역 작업자, 기획자, 개발자가 같은 포맷으로 협업 가능

```swift
Text(LocalizationKey.commonNext.localized(comment: "Next button"))
```

<!--| 문제                                                        | 해결                                                         | 성과                                                         |-->
<!--| ----------------------------------------------------------- | ------------------------------------------------------------ | ------------------------------------------------------------ |-->
<!--| 여러 API 순차 호출로 로딩 지연                              | TaskGroup 병렬 처리                                          | 로딩 시간 40% 단축                                           |-->
<!--| Moya는 completion 기반이라 async/await과 직접 호환되지 않음 | withCheckedThrowingContinuation을 활용한 공통 async 변환 래퍼 구현 | API마다 중복되던 비동기 변환 코드 제거 -> 모든 Repository에서 동일한 async 인터페이스 재사용 |-->
<!--| 화면 이동 로직이 각 View에 분산                             | Generic Coordinator 설계<br />(Route 기반)                   | push/sheet/overlay 화면 전환을 하나의 인터페이스로 통합      |-->



<!-- 
1. `키워드 알림`:등록한 키워드의 팝업이 열리면 알림으로 알려줍니다.
2. `홈`: 키워드 검색과 필터링으로 원하는 팝업을 빠르게 찾을 수 있습니다.
3. `캘린더`: 날짜별로 열리는 팝업 일정을 한눈에 확인할 수 있습니다.
4. `지도`: 내 주변에서 열리는 팝업을 지도에서 확인할 수 있습니다.
5. `찜`: 관심 있는 팝업을 저장해 나만의 리스트와 캘린더로 관리할 수 있습니다.
-->
