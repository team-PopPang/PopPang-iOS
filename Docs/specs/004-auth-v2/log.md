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

## 2026-11-03 push 전 리뷰 지적 반영
- 계기: push 전 리뷰 hook이 FAIL. 사용자 결정 (2026-11-03): 1~6번 고침, 7번(`RegisterChipFlowLayout`과 DSKit `SearchFlowLayout` 중복)·8번(V1 `AuthFeature` 모듈 남김, D-1)은 후속, 완료 버튼은 "시작하기"
- 바꾼 내용:
  - 1번: 완료 화면의 알림 권한 요청을 뺌 (D-6). `NotificationPermissionClient.swift` 삭제, `AppBootstrap` 주입 삭제, 버튼 "시작하기"
  - 2번: 카테고리 목록을 받지 못하면 닉네임 화면 대신 카테고리 단계 칩 자리에 안내와 "다시 시도"를 보여 줌 (`isRecommendListLoadFailed`, `retryRecommendListTapped`)
  - 3번: `validateNicknameResponse`에 확인한 닉네임을 담고, 지금 닉네임과 다르면 결과를 버림 (ProfileFeature와 같은 방식)
  - 4번: 닉네임 확인을 누르면 진행 중인 추천 요청을 취소함
  - 5번: 가입 때 닉네임 중복이면 `errorMessage`를 비워 둠. 중복 안내는 닉네임 확인 문구 하나만 보임
  - 6번: 키워드 5개 제한 알림을 reducer state(`isKeywordLimitAlertPresented`)로 옮김. 화면은 판단하지 않음
  - Demo 앱 Info.plist에 `CFBundleLocalizations`(ko·en·ja) 추가 — S06의 "Demo 앱이 영어로 보임" 확인 필요 해결
- 바꾼 테스트와 이유:
  - `recommendListFailureShowsMessage` → `recommendListFailureCanRetry`: 실패 안내 위치가 `errorMessage`에서 카테고리 단계로 바뀜 (2번)
  - `duplicateNicknameReturnsToNicknameStep`: `errorMessage` 기대를 지움 (5번)
  - `s04KeywordLimitIsFive`: 제한 알림 state 기대를 더함 (6번)
  - `s05StartRequestsPermissionThenCompletes` → `s05StartCompletesImmediately` (D-6)
  - 새 테스트: `staleNicknameCheckIsIgnored` (3번), `validateCancelsPendingRecommendation` (4번)
- 확인:
  - `xcodebuild test … -scheme AuthFeatureV2 -only-testing:AuthFeatureV2Tests` → 통과 (26 tests in 2 suites)
  - `xcodebuild build … -scheme PopPangApp` → BUILD SUCCEEDED
  - `xcodebuild build … -scheme AuthFeatureV2Demo` → BUILD SUCCEEDED
  - iPhone SE(3세대) Demo `-demoStep complete` → 한국어 문구, "시작하기" 버튼 확인

## 2026-11-03 카테고리 단계 선택 개수 문구 숨김
- 사용자 요청 (2026-11-03): "2페이지에서 관심사 선택됨 문장안보이게 수정"
- 바꾼 파일: `RegisterFlowFeatureView.swift` (버튼 위 "관심사 N개 선택됨" 삭제), `Resources/Localizable.xcstrings` (키 삭제), `spec.md` R5
- 확인: 아래 빌드와 Demo `-demoStep category` 캡처

## 2026-11-03 완료 화면 안내 카드 2항목으로 줄임
- 계기: 피그마 2467-10300(팝팡 리뉴얼 최종)의 완료 화면 카드가 2항목(높이 160). 빠진 항목은 이전에 읽은 2467:10950~10955 "찜한 팝업 종료 하루 전 알림 / 마지막 기회를 놓치지 않게"
- 사용자 결정 (2026-11-03): 카드는 피그마처럼 2개, 키워드 단계 아래 칩은 인기 키워드 유지(피그마 메모 "카테고리 추천 키워드"는 따르지 않음), 완료 버튼은 "시작하기" 유지
- 바꾼 파일: `RegisterCompleteStepView.swift` (가운데 항목 삭제), `Resources/Localizable.xcstrings` (키 2개 삭제), `spec.md` R9
- 확인: 아래 빌드와 Demo `-demoStep complete` 캡처
- 확인 필요: 온보딩 아이콘(SVG) 주황 `#EA6D00`과 버튼 `mainOrange` `#FF7A00`이 다름. 피그마 파일의 Color profile(sRGB·Display P3)은 Figma 호출 한도로 확인하지 못함

## 2026-11-03 완료 카드 두 번째 설명 한 줄 맞춤
- 사용자 요청 (2026-11-03): SE에서 "마이 > 알림 설정에서 언제든 바꿀 수 있어요"가 두 줄로 넘어감 → 한 줄로 (작은 화면에서만 줄임)
- 원인: 카드 최대 폭 338, SE는 화면 375 - 양옆 40 = 335라 3pt 모자람
- 바꾼 파일: `RegisterCompleteStepView.swift` — `BenefitRow(prefersSingleLine:)`, `ViewThatFits`로 13pt 한 줄 → 12pt 한 줄 → 13pt 여러 줄 순서. 첫 번째 설명(관심사 나열)은 그대로 여러 줄
- 확인: `xcodebuild build … -scheme AuthFeatureV2Demo` → BUILD SUCCEEDED, iPhone SE(3세대)·iPhone 17 Demo `-demoStep complete` 캡처 → 두 기기 모두 한 줄

## 2026-11-03 키워드를 건너뛴 완료 카드 문구
- 계기: 키워드 단계를 건너뛰면 `isAlerted: false`로 가입하는데 카드가 "키워드 팝업 오픈 알림"을 보여 줌
- 사용자 결정 (2026-11-03): 건너뛰면 1행 "키워드는 나중에 등록해도 돼요 / 마이 > 키워드 알림에서 언제든 추가할 수 있어요", 2행 A안 "가고 싶은 팝업은 찜해 두세요 / 캘린더에 한눈에 모아 드려요"
- 바꾼 파일: `RegisterCompleteStepView.swift` (`hasKeywords`), `RegisterFlowFeatureView.swift`, `Resources/Localizable.xcstrings` (새 키 4개, en·ja needs_review), `spec.md` R9
- 근거: "마이 > 키워드 알림"은 `ProfileFeatureView.swift:57`의 메뉴 이름
- 확인 필요: 키워드를 등록했을 때 1행 설명에 카테고리 이름도 나오는데, 카테고리가 알림 기준인지는 서버 정책 확인 필요
- 후속 (2026-11-03, 사용자 결정): 두 기기 모두 두 줄로 넘어가 "언제든"을 빼고 "마이 > 키워드 알림에서 추가할 수 있어요"로 줄임

## 2026-11-03 두 번째 push 전 리뷰 지적 반영
- 계기: push 전 리뷰 hook FAIL (cbcab62..c18a2ab). 막은 지적 2개와 작은 지적 3개를 고침. 나머지(`isForward` 정리, 칩 배치 중복·측정 횟수, V1 모듈)는 후속
- 사용자 결정 (2026-11-03): 추천 닉네임을 받는 동안 "다음"을 막는다. 건너뛰기는 넣어 둔 키워드를 비우고 가입한다
- 바꾼 내용:
  - 추천 중 다음 막기: `isRecommendingNickname`. 추천 시작 때 true, 응답·직접 입력·확인 때 false. 버튼과 `nextFromNicknameTapped` 둘 다 막음
  - 건너뛰기: `skipTapped`에서 `keywords`·`keywordInput`을 비우고 가입 (`isAlerted: false`)
  - 단계 전환 애니메이션: `stepPages`에 `.animation(value: currentStep)` — 뒤로 가기, 닉네임 중복 복귀, 완료 화면 이동도 밀림
  - 닉네임 확인 규칙: `validateNicknameTapped`가 `localValidationState(for:)`를 씀. 빈 칸은 `.tooShort`
  - 제한 알림 문구: `키워드는 최대 %lld개 까지만 등록 가능합니다.`, `maxKeywordCount` 사용
- 바꾼 테스트와 이유: 추천 관련 테스트 4개에 `isRecommendingNickname` 기대를 더함(새 state), `s05SignupSuccessShowsCompleteStep`에 건너뛰기 때 `keywords = []` 기대를 더함(건너뛰기 동작 변경)
- 새 테스트: `skipSignsUpWithoutKeywords`, `nextIsBlockedWhileRecommending`, `validateUsesLocalRules`
- 확인:
  - `xcodebuild test … -scheme AuthFeatureV2 -only-testing:AuthFeatureV2Tests` → 통과 (29 tests in 2 suites)
  - `xcodebuild build … -scheme PopPangApp` → BUILD SUCCEEDED
  - `xcodebuild build … -scheme AuthFeatureV2Demo` → BUILD SUCCEEDED

## 2026-11-03 세 번째 push 전 리뷰 지적 반영
- 계기: push 전 리뷰 hook FAIL (cbcab62..6fbfa9b). 사용자 결정 (2026-11-03): 1~5번 고침, 칩 배치 중복과 V1 모듈은 후속
- 바꾼 내용:
  - 실패 문구: 뒤로 가기와 닉네임 단계 "다음"에서 `errorMessage`를 지움 (닉네임·키워드 단계가 같은 칸을 씀)
  - 건너뛰기: `isSkippingKeywords`. 요청에만 빈 키워드를 담고, 화면의 키워드는 가입 성공 뒤에 비움. 실패하면 그대로 둠. 가입 요청은 `signup(_:keywords:)`로 모음
  - 빈 카테고리 목록: `.success([])`도 `isRecommendListLoadFailed = true`로 다시 시도를 보여 줌
  - 숨은 단계: 지금 단계가 아닌 화면은 `allowsHitTesting(false)`, `accessibilityHidden(true)`
  - 같은 닉네임: `nicknameChanged`에 지금 닉네임과 같은 값이 오면 무시
- 바꾼 테스트와 이유: `s05SignupSuccessShowsCompleteStep`, `skipSignsUpWithoutKeywords` — 건너뛰기가 `completeRegistrationTapped`를 거치지 않고, 키워드를 성공 뒤에 비우도록 동작이 바뀜
- 새 테스트: `skipFailureKeepsKeywords`, `emptyRecommendListShowsRetry`, `backClearsErrorMessage`, `sameNicknameKeepsValidation`
- 확인:
  - `xcodebuild test … -scheme AuthFeatureV2 -only-testing:AuthFeatureV2Tests` → 통과 (33 tests in 2 suites)
  - `xcodebuild build … -scheme PopPangApp` → BUILD SUCCEEDED
  - `xcodebuild build … -scheme AuthFeatureV2Demo` → BUILD SUCCEEDED

## 2026-11-03 네 번째 push 전 리뷰 지적 반영
- 계기: push 전 리뷰 hook FAIL (cbcab62..eb1e203). 사용자 결정 (2026-11-03): 막은 지적 1~3과 작은 지적 5·6을 고침. 만료 응답 중복 delegate(4), 칩 배치 측정 횟수(7), V1 모듈(8)은 후속
- 바꾼 내용:
  - 키보드: 키워드 단계 "다음"·"건너뛰기"에서 `@FocusState`로 키보드를 내림 (완료 화면의 "시작하기"를 가리지 않게)
  - 빈 닉네임 확인: 빈 칸에서 "확인"을 누르면(`.tooShort`) 안내 문구를 보여 줌. 입력하다 빈 칸이 되면 그대로 숨김
  - 확인 두 번 누름: `validateNicknameTapped`에 `guard !state.isSubmitting`
  - 인기 키워드 중복: 받은 순서를 지키며 중복 제거
  - `nicknameChanged`의 쓰이지 않던 `.checking` 조건 정리
- 새 테스트: `validateIgnoresDoubleTap`, `popularKeywordsAreDeduplicated`
- 확인:
  - `xcodebuild test … -scheme AuthFeatureV2 -only-testing:AuthFeatureV2Tests` → 통과 (35 tests in 2 suites)
  - `xcodebuild build … -scheme PopPangApp` → BUILD SUCCEEDED
  - `xcodebuild build … -scheme AuthFeatureV2Demo` → BUILD SUCCEEDED
- 확인 필요: 키보드 내림과 빈 칸 안내는 화면 동작이라 테스트로 확인하지 못함. Demo에서 직접 눌러 확인 필요

## 2026-11-03 다섯 번째 push 전 리뷰 지적 반영과 리뷰 없이 push
- 계기: push 전 리뷰 hook FAIL (cbcab62..99772aa). 리뷰가 매번 새 지적을 내고, 빈 카테고리 목록 처리는 이전 지적과 반대 방향으로 나옴
- 사용자 결정 (2026-11-03): 1~4번을 고친 뒤 `git push --no-verify`로 push하고 PR을 만든다. 남은 지적은 PR 본문의 후속 작업에 적는다
- 바꾼 내용:
  - 가입 요청 중: 뒤로 가기 버튼을 숨기고 `backTapped`·`nextFromCategoryTapped`를 막음
  - 확인 중 닉네임 수정: 확인 요청을 `CancelID.nicknameValidation`으로 취소하고 `isSubmitting`을 바로 풂
  - 서버 추천 닉네임: `localValidationState(for:)`를 거쳐 규칙에 맞을 때만 `.success`
  - 빈 카테고리 목록: `isRecommendListEmpty`. 회색 "아직 고를 수 있는 카테고리가 없어요" + 다시 시도. 받기 실패는 빨간 문구 그대로
- 바꾼 테스트와 이유: `staleNicknameCheckIsIgnored`(이름은 그대로) — 확인 중 수정하면 요청을 취소하므로 응답을 받지 않고 `isSubmitting`이 바로 false. `emptyRecommendListShowsRetry` — 빈 목록을 실패와 구분
- 새 테스트: `backIsBlockedWhileSubmitting`, `invalidRecommendationIsNotSuccess`
- 확인:
  - `xcodebuild test … -scheme AuthFeatureV2 -only-testing:AuthFeatureV2Tests` → 통과 (37 tests in 2 suites)
  - `xcodebuild build … -scheme PopPangApp` → BUILD SUCCEEDED
  - `xcodebuild build … -scheme AuthFeatureV2Demo` → BUILD SUCCEEDED
- 후속으로 남긴 리뷰 지적: 칩 배치 코드 DSKit 중복과 측정 횟수, V1 `AuthFeature` 모듈 정리(D-1), 가입 화면 새 색 6개의 `PPColor` 토큰화, 가입 단계 만료 때 `loginRequired` 중복 전달, 쓰지 않는 `isForward`
