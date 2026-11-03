# 회원가입 화면 V2 디자인 개발 순서와 체크리스트

- 스펙: [spec.md](spec.md) · 진행 기록: [log.md](log.md)

<!-- 단계 목록의 체크박스가 진행 상태의 기준이다. [x]만 완료로 센다. -->

## 단계 목록

- [x] S01 AuthFeatureV2 모듈을 만들고 앱을 V2로 바꾸기 (화면은 기존과 같음)
- [x] S02 공통 틀과 닉네임 화면 새 디자인, 닉네임 추천 API
- [x] S03 카테고리 화면 새 디자인
- [x] S04 키워드 화면 새 디자인, 인기 키워드 API
- [x] S05 가입 완료 화면과 알림 권한 요청
- [x] S06 작은 화면 대응, 문서 갱신, 전체 검증

공통 명령의 `<sim>`은 `id=7AD2920B-36F6-4B7A-B3B9-14DEE96A5F74`(iPhone 17)다. `xcodebuild` 전에는 `mise exec -- tuist generate --no-open`을 먼저 실행한다. 피그마 값은 spec.md "현재 코드"의 피그마 값 표를 따른다.

## S01 AuthFeatureV2 모듈을 만들고 앱을 V2로 바꾸기 (화면은 기존과 같음)
- 요구사항: R1
- 결정: D-1, D-2
- 할 일:
  - main에서 이슈를 만들고 이슈 브랜치로 옮긴다.
  - `Projects/Features/AuthFeatureV2`를 만든다. 타깃: `AuthFeatureV2`(staticFramework), `AuthFeatureV2Demo`, `AuthFeatureV2Tests`. 의존성은 기존 모듈과 같다(Domain, DSKit, ThirdParty).
  - 기존 `AuthFeature`의 Sources·Resources·Tests를 그대로 복사한다. 타입 이름은 바꾸지 않는다.
  - Demo는 가짜 `AuthFeatureClient`로 가입 흐름(`RegisterFlowFeatureView`)만 띄운다.
  - `Projects/App/Project.swift`, `2. AppBootstrap.swift`, `7. AppRootFlowView.swift`, `8. AppFeature.swift`를 `AuthFeatureV2`로 바꾼다. 기존 모듈은 지우지 않는다.
- 바꿀 파일:
  - `Projects/Features/AuthFeatureV2/` (새 모듈: Project.swift, Sources, Resources, Demo, Tests)
  - `Projects/App/Project.swift`
  - `Projects/App/Sources/AppCore/2. AppBootstrap.swift`
  - `Projects/App/Sources/AppCore/Navigation/7. AppRootFlowView.swift`, `8. AppFeature.swift`
  - `Workspace.swift` (모듈 목록이 있으면)
- 완료 조건:
  - `xcodebuild test -workspace PopPang.xcworkspace -scheme AuthFeatureV2 -destination <sim> -only-testing:AuthFeatureV2Tests` → 기대: 옮긴 9개 통과 (이 단계 전에는 scheme이 없어 실패)
  - `rg -n "import AuthFeature$" Projects/App` → 기대: 결과 없음
  - `xcodebuild build -workspace PopPang.xcworkspace -scheme PopPangApp -destination <sim>` → 기대: BUILD SUCCEEDED
  - 확인할 동작: 시뮬레이터에서 로그인과 가입 화면이 기존과 같게 나온다

## S02 공통 틀과 닉네임 화면 새 디자인, 닉네임 추천 API
- 요구사항: R1, R2, R3, R4
- 결정: D-3, D-4
- 할 일:
  - Data: `AuthAPI`에 `.signupNicknameRecommendation`(`GET /user/nickname/recommendation`, 가입 토큰) 추가, 응답 DTO 추가, `AuthRepositoryImpl.recommendSignupNickname()` 구현. 가입 토큰 만료는 기존과 같이 `signupSessionExpired`, 그 밖의 실패는 `failed`.
  - Domain: `AuthRepositoryProtocol`·`AuthUsecaseProtocol`·`AuthUsecaseImpl`에 `recommendSignupNickname() -> String` 추가. 이 프로토콜을 따르는 가짜 객체도 고친다.
  - `AuthFeatureClient`에 `recommendNickname` 추가, AppBootstrap 주입은 `live(authUsecase:)`가 그대로 처리한다.
  - DSKit `UIConstants.swift`에 D-4의 새 색 6개를 추가한다.
  - 공통 틀: 상단(뒤로 `chevron.left`, 진행 막대 270×4, `n/3`), 제목 ExtraBold 24, 아래 버튼(모서리 10, 52, Medium 15). 닉네임 단계는 뒤로를 숨긴다 (A-1). 건너뛰기는 상단에서 뺀다.
  - 닉네임 화면: 입력칸 + 확인 버튼 + 결과 문구 (A-3), "다른 닉네임 추천받기" 캡슐 버튼 (A-8).
  - Reducer: 진입 시 추천 닉네임을 받아 채우고 `.success`, 추천받기 → 새 추천, 실패 시 빈 칸 그대로.
  - 새 문구 ko·en·ja를 `Localizable.xcstrings`에 넣는다.
  - 테스트: 이름에 `S02`를 넣는다. 진입 시 추천 채움·`.success`, 추천받기로 바뀜, 추천 실패 시 빈 칸, Data 경로·권한·디코딩.
- 바꿀 파일:
  - `Projects/Data/Sources/Remote/Auth/AuthAPI.swift`
  - `Projects/Data/Sources/DTO/Auth/` (새 DTO)
  - `Projects/Data/Sources/RepositoryImpl/AuthRepositoryImpl.swift`
  - `Projects/Data/Tests/AuthRepositoryTests.swift`
  - `Projects/Domain/Sources/RepositoryProtocol/AuthRepositoryProtocol.swift`
  - `Projects/Domain/Sources/Usecase/Protocols/AuthUsecaseProtocol.swift`, `Implementations/AuthUsecaseImpl.swift`
  - `Projects/Shared/DSKit/Sources/Support/UIConstants.swift`
  - `Projects/Features/AuthFeatureV2/Sources/Dependency/AuthFeatureClient.swift`
  - `Projects/Features/AuthFeatureV2/Sources/Presentation/RegisterFlowFeature.swift`, `RegisterFlowFeatureView.swift` (단계별 View는 새 파일로 나눌 수 있음)
  - `Projects/Features/AuthFeatureV2/Resources/Localizable.xcstrings`
  - `Projects/Features/AuthFeatureV2/Tests/AuthFeatureV2Tests.swift`
- 완료 조건:
  - `xcodebuild test -workspace PopPang.xcworkspace -scheme AuthFeatureV2 -destination <sim> -only-testing:AuthFeatureV2Tests` → 기대: S02 테스트를 포함해 통과 (이 단계 전에는 S02 테스트가 없어 실패)
  - `xcodebuild test -workspace PopPang.xcworkspace -scheme Data -destination <sim> -only-testing:DataTests/AuthRepositoryTests` → 기대: 추천 API 테스트를 포함해 통과
  - `xcodebuild build -workspace PopPang.xcworkspace -scheme PopPangApp -destination <sim>` → 기대: BUILD SUCCEEDED
  - 확인할 동작: Demo나 앱에서 닉네임 화면이 피그마(2467-10836 + 추천받기)와 같아 보이고, 추천받기를 누르면 닉네임이 바뀐다

## S03 카테고리 화면 새 디자인
- 요구사항: R5
- 할 일:
  - 제목 "어떤 팝업을\n좋아하세요?", 라벨 "카테고리", 칩(기본·선택) 줄바꿈 배치, 버튼 위 "관심사 N개 선택됨".
  - 카테고리 단계의 건너뛰기를 없앤다 (A-2). 1개 이상 골라야 다음.
  - 새 문구 ko·en·ja 추가.
  - 테스트: 이름에 `S03`. 카테고리 단계에서 `skipTapped`가 아무것도 하지 않는다.
- 바꿀 파일:
  - `Projects/Features/AuthFeatureV2/Sources/Presentation/RegisterFlowFeature.swift`, 카테고리 단계 View
  - `Projects/Features/AuthFeatureV2/Resources/Localizable.xcstrings`
  - `Projects/Features/AuthFeatureV2/Tests/AuthFeatureV2Tests.swift`
- 완료 조건:
  - `xcodebuild test -workspace PopPang.xcworkspace -scheme AuthFeatureV2 -destination <sim> -only-testing:AuthFeatureV2Tests` → 기대: S03 테스트를 포함해 통과 (이 단계 전에는 카테고리 건너뛰기가 키워드로 넘어가서 실패)
  - 확인할 동작: 카테고리 화면이 피그마(2467-10856, 지역 문구 제외)와 같아 보이고, 칩을 누르면 선택 모양과 요약 개수가 바뀐다

## S04 키워드 화면 새 디자인, 인기 키워드 API
- 요구사항: R6, R7, R10
- 결정: D-3
- 할 일:
  - Data·Domain: `.popularAlertKeywords`(`GET /alert-keyword/popular`, 가입 토큰), DTO, `fetchPopularKeywords() -> [String]`. 가짜 객체도 고친다.
  - `AuthFeatureClient`에 `getPopularKeywords` 추가.
  - 화면: 제목·부제목, 제목 줄 오른쪽 건너뛰기, 입력칸(돋보기 + 안내) + 검정 추가 버튼, "내 키워드" + `N / 5`, 내 키워드 칩(× 삭제), "많이 등록한 키워드" + "+ 키워드" 칩.
  - 인기 키워드는 진입 시 한 번 받고, 실패·빈 배열이면 영역을 숨긴다. 칩을 누르면 직접 추가와 같은 규칙(5개, 중복)으로 추가한다 (A-6).
  - 키워드 추가 때 알림 권한을 묻는 코드를 뺀다 (R10).
  - 새 문구 ko·en·ja 추가.
  - 테스트: 이름에 `S04`. 인기 키워드 로드, 칩 탭 → 추가, 5개 제한, 실패 시 빈 목록. Data 경로·권한·디코딩(빈 배열 포함).
- 바꿀 파일:
  - `Projects/Data/Sources/Remote/Auth/AuthAPI.swift`, `Projects/Data/Sources/DTO/Auth/` (새 DTO), `Projects/Data/Sources/RepositoryImpl/AuthRepositoryImpl.swift`, `Projects/Data/Tests/AuthRepositoryTests.swift`
  - `Projects/Domain/Sources/RepositoryProtocol/AuthRepositoryProtocol.swift`, `Projects/Domain/Sources/Usecase/Protocols/AuthUsecaseProtocol.swift`, `Implementations/AuthUsecaseImpl.swift`
  - `Projects/Features/AuthFeatureV2/Sources/Dependency/AuthFeatureClient.swift`
  - `Projects/Features/AuthFeatureV2/Sources/Presentation/RegisterFlowFeature.swift`, 키워드 단계 View
  - `Projects/Features/AuthFeatureV2/Resources/Localizable.xcstrings`
  - `Projects/Features/AuthFeatureV2/Tests/AuthFeatureV2Tests.swift`
- 완료 조건:
  - `xcodebuild test -workspace PopPang.xcworkspace -scheme AuthFeatureV2 -destination <sim> -only-testing:AuthFeatureV2Tests` → 기대: S04 테스트를 포함해 통과 (이 단계 전에는 인기 키워드 액션이 없어 실패)
  - `xcodebuild test -workspace PopPang.xcworkspace -scheme Data -destination <sim> -only-testing:DataTests/AuthRepositoryTests` → 기대: 인기 키워드 테스트를 포함해 통과
  - `rg -n "requestAuthorization" Projects/Features/AuthFeatureV2/Sources` → 기대: 키워드 단계 View에 결과 없음
  - 확인할 동작: 키워드 화면이 피그마(2467-10890, 제목은 "많이 등록한 키워드")와 같아 보이고, 인기 키워드를 누르면 내 키워드에 추가된다

## S05 가입 완료 화면과 알림 권한 요청
- 요구사항: R8, R9, R10
- 결정: D-5
- 할 일:
  - `RegisterRoute`에 `.complete`를 더한다. 진행 막대·`n/3`은 앞의 3단계만 센다. 완료 단계에서는 상단 바를 숨긴다.
  - 가입 성공 시 `signedUpUser`에 저장하고 `.complete`로 간다. `completed`는 아직 보내지 않는다.
  - 완료 화면: 체크 아이콘, 제목(닉네임만 주황), 안내 카드 3항목(1번 설명은 고른 카테고리 이름과 키워드를 " · "로 잇는다, 그림자 A-7), "알림 켜고 시작하기".
  - 버튼: 알림 권한 요청 → 결과와 관계없이 `.delegate(.completed(user))` (A-5). 권한 요청은 client로 감싸 테스트에서 바꿀 수 있게 한다.
  - 후속 변경 (2026-11-03, D-6): 버튼을 "시작하기"로 바꾸고 알림 권한을 묻지 않는다. 알림 권한 client는 지웠다. 자세한 내용은 `log.md`의 "push 전 리뷰 지적 반영"을 본다.
  - 새 문구 ko·en·ja 추가.
  - 테스트: 이름에 `S05`. 가입 성공 → `.complete`이고 `completed` 없음, 완료 버튼 → 권한 요청 후 `completed(user)`, 권한 거부여도 `completed`.
- 바꿀 파일:
  - `Projects/Features/AuthFeatureV2/Sources/Presentation/RegisterFlowFeature.swift`, `RegisterFlowFeatureView.swift`, 완료 단계 View (새 파일)
  - `Projects/Features/AuthFeatureV2/Sources/Dependency/` (알림 권한 client, 새 파일 또는 기존 client에 추가)
  - `Projects/Features/AuthFeatureV2/Resources/Localizable.xcstrings`
  - `Projects/Features/AuthFeatureV2/Tests/AuthFeatureV2Tests.swift`
- 완료 조건:
  - `xcodebuild test -workspace PopPang.xcworkspace -scheme AuthFeatureV2 -destination <sim> -only-testing:AuthFeatureV2Tests` → 기대: S05 테스트를 포함해 통과 (이 단계 전에는 가입 성공 즉시 `completed`를 보내서 실패)
  - `xcodebuild build -workspace PopPang.xcworkspace -scheme PopPangApp -destination <sim>` → 기대: BUILD SUCCEEDED
  - 확인할 동작: 실제 가입으로 키워드 다음 → 완료 화면(피그마 2467-10931) → 버튼 → 알림 권한 팝업 → 메인 화면

## S06 작은 화면 대응, 문서 갱신, 전체 검증
- 요구사항: R1
- 할 일:
  - iPhone SE에서 잘리는 곳이 있으면 고친다 (칩 영역 스크롤, 완료 화면 간격 등).
  - `Docs/architecture`의 모듈 목록·의존성 문서에 `AuthFeatureV2`를 더하고 앱이 V2를 쓴다고 적는다. `Docs/architecture/api-v2-migration.md`에 새 API 2개를 적는다.
  - `Docs/development/testing.md`에 `AuthFeatureV2Tests` 줄과 실행 명령을 더한다.
  - 전체 테스트와 빌드를 다시 돌린다.
- 바꿀 파일:
  - `Projects/Features/AuthFeatureV2/Sources/Presentation/` (필요한 View)
  - `Docs/architecture/` 의 모듈 문서, `Docs/architecture/api-v2-migration.md`
  - `Docs/development/testing.md`
- 완료 조건:
  - `rg -n "AuthFeatureV2" Docs/architecture Docs/development/testing.md` → 기대: 결과 있음 (이 단계 전에는 없음)
  - `xcodebuild test -workspace PopPang.xcworkspace -scheme AuthFeatureV2 -destination <sim> -only-testing:AuthFeatureV2Tests` → 기대: 통과
  - `xcodebuild test -workspace PopPang.xcworkspace -scheme Data -destination <sim> -only-testing:DataTests` → 기대: 통과
  - `xcodebuild build -workspace PopPang.xcworkspace -scheme PopPangApp -destination <sim>` → 기대: BUILD SUCCEEDED
  - 확인할 동작: iPhone SE(3세대) 시뮬레이터에서 4장 모두 버튼과 글자가 잘리지 않는다
