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
> 🔸 **로딩 시간 40% 단축**

---

### **2. Moya와 async/await 비호환**
> **문제**  
> Moya는 completion 기반이라 async/await과 직접 호환되지 않아  
> API마다 변환 코드가 반복됨  
>
> **해결**  
> `withCheckedThrowingContinuation` 기반 **공통 async 변환 래퍼** 구현  
>
> **성과**  
> 🔸 Repository 전 구간 **async 인터페이스 표준화**  
> 🔸 **중복 코드 제거 + 유지보수성 대폭 향상**

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
```

---

### **3. 화면 이동 로직 분산**
> **문제**  
> push / sheet / overlay 화면 전환 코드가 각 View에 흩어져 구조가 복잡함  
>
> **해결**  
> Route 기반 **Generic Coordinator** 설계로 화면 이동을 중앙 집중화  
>
> **성과**  
> 🔸 화면 이동 로직 **한 곳에서 관리**  
> 🔸 **확장성 높은 네비게이션 구조 확보**

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
