# 회원가입 화면 V2 디자인 테크 스펙 진행 기록

- 스펙: [spec.md](spec.md) · 체크리스트: [tasks.md](tasks.md)

<!-- 덧붙이기만 한다. 이전 기록은 고치지 않는다. -->

## 2026-11-02 시작

- 스펙 폴더를 만들었다.
- 인터뷰 4차까지 마쳤다. 남은 항목은 가정 A-1~A-10으로 두었다.
- 승인: 설계 (2026-11-02) — "승인". D-1~D-5와 AI가 정한 세부 7개를 확인받았다.
- 승인: 테크 스펙 (2026-11-02) — "승인".
- 체크리스트 S01~S06을 썼다.
- 승인: 체크리스트 (2026-11-02) — "승인".

## 2026-11-02 S01 AuthFeatureV2 모듈을 만들고 앱을 V2로 바꾸기
- 시작: cbcab62, 이슈 #138, 브랜치 `feature/#138` (관련 없는 변경: 미추적 `.obsidian/`, `Docs/specs/002-popup-detail-v2/` — 건드리지 않음)
- 바꾼 파일: `Projects/Features/AuthFeatureV2/` (새 모듈: Project.swift, Sources 5개, Resources/Localizable.xcstrings, Demo/Sources/AuthFeatureV2DemoApp.swift, Tests/AuthFeatureV2Tests.swift), `Projects/App/Project.swift`, `Projects/App/Sources/AppCore/2. AppBootstrap.swift`, `Navigation/7. AppRootFlowView.swift`, `Navigation/8. AppFeature.swift`
- 완료 조건:
  - `xcodebuild test … -scheme AuthFeatureV2 -only-testing:AuthFeatureV2Tests` → 통과 (9 tests in 2 suites)
  - `rg -n "import AuthFeature$" Projects/App` → 결과 없음
  - `xcodebuild build … -scheme PopPangApp` → BUILD SUCCEEDED
  - 확인할 동작: 앱 설치·실행 → 온보딩까지 정상. 로그인·가입 화면은 소셜 로그인이 필요해 사용자 확인 필요
- 판단: Demo는 가짜 client로 가입 흐름(`RegisterFlowFeatureView`)만 띄움 — tasks.md 그대로 — 틀리면 Demo 파일만 바꾸면 됨
- 판단: 테스트 struct 이름을 `AuthFeatureV2Tests`로 바꿈 — 파일 이름과 맞춤 — 영향 없음
- 확인 필요: Tuist가 Demo 타깃 scheme을 만들지 않아 `AuthFeatureV2Demo`를 명령줄로 실행할 수 없음 (`OnboardingFeatureV2Demo`도 같음). Xcode에서 scheme을 직접 추가해야 함
- 결과: 미완료 ([ ]) — 사용자 확인 대기
- 사용자 확인 (2026-11-02): 로그인·가입 화면이 기존과 같음 — "확인". 결과: 완료 ([x])

## 2026-11-02 S02 공통 틀과 닉네임 화면 새 디자인, 닉네임 추천 API
- 시작: cbcab62 + S01 변경 (커밋 없음), 브랜치 `feature/#138`
- 바꾼 파일: `Data/Sources/Remote/Auth/AuthAPI.swift`, `Data/Sources/DTO/Auth/NicknameRecommendationDTO.swift` (새 파일), `Data/Sources/RepositoryImpl/AuthRepositoryImpl.swift`, `Data/Tests/AuthRepositoryTests.swift`, `Domain/.../AuthRepositoryProtocol.swift`, `AuthUsecaseProtocol.swift`, `AuthUsecaseImpl.swift`, `Shared/DSKit/Sources/Support/UIConstants.swift`, `AuthFeatureV2/Sources/Dependency/AuthFeatureClient.swift`, `RegisterFlowFeature.swift`, `RegisterFlowFeatureView.swift`, `RegisterComponents.swift` (새 파일), `Resources/Localizable.xcstrings`, `Tests/AuthFeatureV2Tests.swift`, `Demo/Sources/AuthFeatureV2DemoApp.swift`, `AuthFeatureV2/Project.swift`
- 완료 조건:
  - `xcodebuild test … -scheme AuthFeatureV2 -only-testing:AuthFeatureV2Tests` → 통과 (14 tests, S02 5개 포함)
  - `xcodebuild test … -scheme Data -only-testing:DataTests/AuthRepositoryTests` → 통과 (27 tests, S02 3개 포함)
  - `xcodebuild build … -scheme PopPangApp` → BUILD SUCCEEDED
  - 확인할 동작: Demo 실행 화면이 피그마 2467-10836 + 추천받기 배치와 같음 → 캡처로 확인함. 추천받기로 바뀌는 동작은 S02 테스트로 확인
- 판단: 피그마 수치는 화면 코드에 흩지 않고 모듈 안 `RegisterLayout`에 모음 — design-system.md는 토큰 사용을 권하지만 PPRadius 등에 없는 값이고 온보딩 V2 선례도 같음 — 틀리면 토큰 추가 후 `RegisterLayout`만 바꾸면 됨
- 판단: 닉네임 화면 진입 시 자동 키보드 포커스를 뺌 — 추천 닉네임이 채워져 있고 피그마에 키보드가 없음 — 틀리면 `.task` 한 줄 복구
- 판단: 직접 입력하면 진행 중인 추천 요청을 취소함 — 늦게 온 추천이 입력을 덮어쓰지 않게 — 영향 작음
- 판단: 상단 건너뛰기를 지금 뺌 (tasks.md대로). 키워드 단계 건너뛰기는 S04에서 제목 줄에 다시 넣으므로 S03~S04 사이에는 건너뛰기가 없음
- 판단: 안 쓰게 된 옛 문구 4개("닉네임을\n설정해주세요." 등)를 V2 카탈로그에서 지움
- 판단: tasks.md에 없던 `AuthFeatureV2Demo` scheme을 Project.swift에 추가 — Demo를 실행하려면 필요, `AlertFeature`와 같은 방식 — S01의 "확인 필요" 해결
- 확인 필요: Demo 앱은 한국어 지역화가 등록되지 않아 시뮬레이터에서 영어 문구로 보임 (앱 본체는 한국어)
- 결과: 완료 ([x])

## 2026-11-02 S03 카테고리 화면 새 디자인
- 시작: cbcab62 + S01·S02 변경 (커밋 없음), 브랜치 `feature/#138`
- 바꾼 파일: `AuthFeatureV2/Sources/Presentation/RegisterFlowFeature.swift` (카테고리 단계 `skipTapped` 무시), `RegisterFlowFeatureView.swift` (카테고리 단계 View), `RegisterComponents.swift` (`RegisterSectionLabel`, `RegisterChip`, `RegisterChipFlowLayout`, 칩 수치), `Resources/Localizable.xcstrings`, `Tests/AuthFeatureV2Tests.swift`, `Demo/Sources/AuthFeatureV2DemoApp.swift`
- 완료 조건:
  - `xcodebuild test … -scheme AuthFeatureV2 -only-testing:AuthFeatureV2Tests` → 통과 (17 tests, S03 3개 포함)
  - 확인할 동작: Demo를 `-demoStep category`로 띄워 캡처 → 제목·"카테고리" 라벨·칩(선택 "✓ 디저트")·"관심사 1개 선택됨"·다음 버튼 배치가 피그마 2467-10856과 같음. 칩 선택·해제와 개수 변화는 S03 테스트로 확인
- 판단: 칩 간격(가로·세로 8)을 맞추려고 모듈 안에 `RegisterChipFlowLayout`을 새로 씀 — DSKit `SearchFlowLayout`은 간격이 없고 `FlowLayout`은 모양이 다름 — S04 키워드 칩도 이것을 씀
- 판단: "관심사 N개 선택됨"은 0개일 때도 보여 줌 — 피그마에 숨김 조건이 없음 — 틀리면 View 조건 한 줄
- 판단: Demo에 `-demoStep category` 실행 인자를 추가 — 탭 없이 카테고리 단계를 캡처하려고 — Demo 전용
- 판단: 안 쓰게 된 옛 문구 2개("추천 받고 싶은 항목을\n선택해주세요.", "선택하신 항목에 맞게 추천해드려요")를 지움
- 참고: iPhone 17(폭 402)에서는 첫 줄에 칩 5개가 들어감. 피그마(폭 393)는 4개. 화면 폭 차이라 정상
- 확인 필요: Demo는 여전히 영어 문구로 보임 (S02와 같음)
- 결과: 완료 ([x])

## 2026-11-03 S04 키워드 화면 새 디자인, 인기 키워드 API
- 시작: cbcab62 + S01~S03 변경 (커밋 없음), 브랜치 `feature/#138`
- 바꾼 파일: `Data/Sources/Remote/Auth/AuthAPI.swift` (`.popularAlertKeywords`), `Data/Sources/DTO/Auth/PopularAlertKeywordDTO.swift` (새 파일), `Data/Sources/RepositoryImpl/AuthRepositoryImpl.swift`, `Data/Tests/AuthRepositoryTests.swift`, `Domain/.../AuthRepositoryProtocol.swift`, `AuthUsecaseProtocol.swift`, `AuthUsecaseImpl.swift`, `AuthFeatureV2/Sources/Dependency/AuthFeatureClient.swift`, `RegisterFlowFeature.swift`, `RegisterFlowFeatureView.swift`, `RegisterComponents.swift`, `Resources/Localizable.xcstrings`, `Tests/AuthFeatureV2Tests.swift`, `Demo/Sources/AuthFeatureV2DemoApp.swift`
- 완료 조건:
  - `xcodebuild test … -scheme AuthFeatureV2 -only-testing:AuthFeatureV2Tests` → 통과 (22 tests, S04 5개 포함)
  - `xcodebuild test … -scheme Data -only-testing:DataTests/AuthRepositoryTests` → 통과 (30 tests, S04 3개 포함)
  - `rg -n "requestAuthorization" Projects/Features/AuthFeatureV2/Sources` → 결과 없음
  - `xcodebuild build … -scheme PopPangApp` → BUILD SUCCEEDED
  - 확인할 동작: Demo를 `-demoStep keyword`로 띄워 캡처 → 제목·부제목·건너뛰기·입력칸+추가·"내 키워드 2 / 5"·내 키워드 칩·"많이 등록한 키워드"+"+ 키워드" 칩 배치가 피그마 2467-10890과 같음. 인기 키워드 탭 → 추가는 S04 테스트로 확인
- 판단: 인기 키워드는 키워드 단계가 아니라 가입 흐름 진입(`onAppear`) 때 한 번 받음 — 세 단계 View가 함께 그려져 단계 진입 시점이 따로 없고, 키워드 단계에 왔을 때 이미 준비됨 — `hasRequestedPopularKeywords`로 빈 배열이어도 다시 받지 않음
- 판단: 인기 키워드 요청이 가입 단계 만료를 받으면 다른 가입 API처럼 `loginRequired`. 그 밖의 실패는 영역만 숨김
- 판단: 인기 키워드 탭은 새 액션 `popularKeywordTapped`로 받음 — `keywordAdded`는 입력칸을 비우는데 인기 키워드 탭은 입력 중인 글자를 지우면 안 됨
- 판단: 기존 테스트 3개(카테고리 실패, S02 추천 실패·입력 유지)의 시작 state에 `hasRequestedPopularKeywords = true`를 넣음 — 기대값은 그대로이고, `recommendList`를 미리 채워 카테고리 요청을 빼던 방식과 같음
- 판단: `RegisterChip`을 `Style`(normal·selected·added)로 바꿈. 글자("✓ ", "  ×", "+ ")는 부르는 쪽에서 만듦
- 판단: 5개 초과 알림(A-6)은 View에서 띄우고, 인기 키워드 탭에도 같은 알림을 씀
- 판단: 안 쓰게 된 옛 문구 9개(알림 권한 알림 4개, 옛 키워드 화면 5개)를 지움
- 참고: iPhone 17 시뮬레이터에 Apple 계정 시스템 알림이 떠 있어 캡처는 SE에서 함
- 확인 필요 (S06): SE에서 아래 "다음" 버튼이 화면 아래 끝에 붙음(홈 인디케이터가 없어 safe area 아래 여백 0). 영어 입력칸 안내 문구가 SE에서 잘림
- 결과: 완료 ([x])

## 2026-11-03 S05 가입 완료 화면과 알림 권한 요청
- 시작: cbcab62 + S01~S04 변경 (커밋 없음), 브랜치 `feature/#138`
- 바꾼 파일: `AuthFeatureV2/Sources/Dependency/NotificationPermissionClient.swift` (새 파일), `RegisterFlowFeature.swift` (`.complete` 단계, `signedUpUser`, `startTapped`, `notificationPermissionResponse`), `RegisterFlowFeatureView.swift`, `RegisterCompleteStepView.swift` (새 파일), `Resources/Localizable.xcstrings`, `Tests/AuthFeatureV2Tests.swift`, `Demo/Sources/AuthFeatureV2DemoApp.swift`
- 완료 조건:
  - `xcodebuild test … -scheme AuthFeatureV2 -only-testing:AuthFeatureV2Tests` → 통과 (24 tests, S05 2개(권한 허용·거부 2케이스) 포함)
  - `xcodebuild build … -scheme PopPangApp` → BUILD SUCCEEDED
  - 확인할 동작: Demo를 `-demoStep complete`로 띄워 캡처 → 체크 아이콘·제목(닉네임 주황)·안내 카드 3항목·버튼 배치가 피그마 2467-10931과 같음. 실제 가입 → 완료 화면 → 알림 권한 팝업 → 메인은 소셜 로그인이 필요해 사용자 확인 필요
- 판단: 기존 테스트 `completeRegistrationSignsUp`의 기대값을 "가입 성공 → `completed`"에서 "가입 성공 → `.complete` 단계"로 바꿈 — R8·D-5로 동작 자체가 바뀐 것이고 tasks.md 완료 조건에 적힌 변화 — 제목도 같이 고침
- 판단: 알림 권한 client는 usecase가 없는 시스템 API라 `liveValue`에 실제 구현을 둠(AppBootstrap 주입 없음). `testValue`는 부르면 테스트 실패로 알림
- 판단: 권한을 허용하면 `registerForRemoteNotifications()`를 부름 — 앱 시작 때(`AppNotificationManager.configureNotification`) 권한이 없었으면 APNs 등록이 안 돼 푸시 토큰을 받지 못함
- 판단: 완료 단계에서 상단 바는 `opacity 0`으로 숨기고 자리는 남김 — 옆으로 밀리는 단계 화면 높이가 바뀌지 않게. 완료 화면 위치 값은 상단 바 37을 뺀 값
- 판단: 완료 단계에서는 뒤로·건너뛰기를 무시함
- 확인 필요 (S06): SE에서 영어 문구일 때 카드와 버튼이 붙음. iPhone 17 시뮬레이터에는 여전히 Apple 계정 시스템 알림이 떠 있음
- 결과: 미완료 ([ ]) — 사용자 확인 대기 (실제 가입 흐름)
- 사용자 확인 (2026-11-03): 실제 가입 → 완료 화면 → 알림 권한 → 메인 — "확인". 결과: 완료 ([x])

## 2026-11-03 S06 작은 화면 대응, 문서 갱신, 전체 검증
- 시작: cbcab62 + S01~S05 변경 (커밋 없음), 브랜치 `feature/#138`
- 바꾼 파일: `AuthFeatureV2/Sources/Presentation/RegisterFlowFeatureView.swift` (홈 바 없는 기기 아래 여백, 카테고리·키워드 위쪽 스크롤), `RegisterComponents.swift`, `RegisterCompleteStepView.swift` (낮은 화면 간격), `Resources/Localizable.xcstrings` (영어 입력칸 안내 줄임), `Docs/architecture/architecture.md`, `dependency-injection.md`, `api-v2-migration.md`, `Docs/development/testing.md`
- 완료 조건:
  - `rg -n "AuthFeatureV2" Docs/architecture Docs/development/testing.md` → 9줄
  - `xcodebuild test … -scheme AuthFeatureV2 -only-testing:AuthFeatureV2Tests` → 통과 (24 tests)
  - `xcodebuild test … -scheme Data -only-testing:DataTests` → 통과 (83 tests in 7 suites)
  - `xcodebuild build … -scheme PopPangApp` → BUILD SUCCEEDED
  - 확인할 동작: iPhone SE(3세대)에서 Demo 4장(닉네임·카테고리·키워드·완료)을 영어 문구로 캡처 → 버튼·글자 잘림 없음, 버튼 아래 여백 16
- 판단: 홈 바 없는 기기의 아래 여백 16은 온보딩 V2와 같은 방식(`safeAreaInsets.bottom == 0`)
- 판단: 카테고리·키워드 단계는 버튼 위 내용만 스크롤하게 함 — 카테고리가 많거나 키보드가 올라와도 버튼이 밀리지 않음
- 판단: 완료 화면은 높이 680 미만이면 아이콘 위 16, 카드 위 28로 줄임
- 판단: 영어 입력칸 안내를 "e.g. Shin-chan, LEGO"로 줄임 — SE에서 말줄임표로 잘림
- 판단: `dependency-injection.md`의 "`liveValue`에 실제 구현을 넣지 않는다" 규칙에 `NotificationPermissionClient`를 예외로 적음 — usecase 없는 시스템 API. 규칙대로 하려면 `AppBootstrap`에서 주입해야 함 (사용자 결정 필요)
- 판단: `testing.md`의 Data 테스트 수를 77 → 83으로 고침
- 확인 필요: Demo 앱은 한국어 지역화가 등록되지 않아 영어로 보임 (S02부터). 앱 본체는 한국어
- 결과: 완료 ([x])
- 상태 변경: 모든 단계 완료 → `상태: 완료` (2026-11-03)

## 2026-11-03 S06 후속: 알림 권한 client를 DI 규칙에 맞춤
- 사용자 결정 (2026-11-03): "규칙에 맞추기로 해줘" — S06 판단의 예외 대신 `dependency-injection.md` 규칙을 따름
- 바꾼 파일: `AuthFeatureV2/Sources/Dependency/NotificationPermissionClient.swift` (`live`·`unimplemented` 분리, `liveValue`·`testValue` = `unimplemented`), `App/Sources/AppCore/2. AppBootstrap.swift` (`$0.notificationPermissionClient = .live`), `Docs/architecture/dependency-injection.md` (예외 문구 지우고 composition root 그림에 추가)
- 확인:
  - `xcodebuild test … -scheme AuthFeatureV2 -only-testing:AuthFeatureV2Tests` → 통과 (24 tests)
  - `xcodebuild build … -scheme PopPangApp` → BUILD SUCCEEDED
  - `xcodebuild build … -scheme AuthFeatureV2Demo` → BUILD SUCCEEDED (Demo는 가짜 client를 그대로 주입)
- 확인 필요: 실제 가입 완료 화면에서 알림 권한 팝업이 다시 뜨는지 앱에서 한 번 확인 (주입 경로만 바뀜)
