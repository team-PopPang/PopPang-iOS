# Logger

## FirebaseLogger 적용 범위

V0의 `FirebaseLogger`는 화면 전체에 자동 적용된 로거가 아니라 `MainTabView`의 탭 화면에만 수동으로 붙어 있다.

V0 기준 로그 지점:

- `HomeView().trackScreen("HomeView")`
- `CalendarView().trackScreen("CalendarView")`
- `MapView().trackScreen("MapView")`
- `FavoriteView(selectedTab: $selectedTab).trackScreen("FavoriteView")`
- `ProfileView().trackScreen("ProfileView")`

즉 현재 Firebase screen_view 이벤트는 메인 탭 5개 화면 진입만 대상으로 한다. 검색, 팝업 상세, 리뷰, 알림, 프로필 하위 화면은 V0 기준으로는 `trackScreen`이 붙어 있지 않다.

## V0 구현

V0 파일:

- `V0/PopPang/Sources/Util/Logger/FirebaseLogger.swift`
- `V0/PopPang/Sources/Presentation/MainTab/MainTabView.swift`

V0의 modifier는 `onAppear`에서 아래 이벤트를 보낸다.

- event: `AnalyticsEventScreenView`
- parameter `AnalyticsParameterScreenName`: 전달받은 화면 이름
- parameter `AnalyticsParameterScreenClass`: 전달받은 화면 이름

## 모듈러 구현 원칙

외부 SDK product 선언은 `Projects/Shared/ThirdParty`에 모은다. 다른 모듈은 `ThirdParty` 타깃에 의존하되, SDK를 직접 써야 하는 source에서는 실제 SDK 모듈명을 명시적으로 import한다.

다만 Firebase 계열은 SPM static/auto-link 의존이 많아서 App source에서 `import FirebaseAnalytics` 또는 `import FirebaseCore`를 직접 붙이면 App 링크 단계에서 `FirebaseCoreInternal`, `GoogleAppMeasurement` 계열 심볼 누락이 재현될 수 있다. 그래서 모듈러 App의 `FirebaseLogger`는 V0의 `trackScreen(_:)` 호출 형태를 유지하되, FirebaseAnalytics Swift 모듈을 직접 import하지 않고 런타임 Objective-C bridge로 `FIRAnalytics.logEventWithName(_:parameters:)`를 호출한다. App 시작 시 `FirebaseApp.configure()`에 해당하는 호출도 같은 이유로 `FIRApp` bridge를 사용한다.

이 방식의 목적:

- V0의 `trackScreen("...")` 사용 코드를 유지한다.
- Firebase static product를 여러 모듈에 직접 링크해서 중복/링크 오류를 만들지 않는다.
- `FirebaseApp.configure()`와 `GoogleService-Info.plist`는 App 조립 계층에서 유지한다.
- FCM token 수신은 `FIRMessaging` bridge delegate와 명시적 token 요청으로 확인 가능하게 유지한다.

## 추가 적용 규칙

새 화면에 screen log를 추가할 때는 먼저 V0에 해당 로그가 있었는지 확인한다. V0에 없는 화면 로그를 새로 추가하는 것은 parity 작업이 아니라 분석 정책 변경이므로 별도 의사결정으로 다룬다.
