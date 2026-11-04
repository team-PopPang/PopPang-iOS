# 팝업 상세 화면 V2 전환 진행 기록

- 스펙: [spec.md](spec.md) · 체크리스트: [tasks.md](tasks.md)

<!-- 덧붙이기만 한다. 이전 기록은 고치지 않는다. -->

## 2026-10-30 시작

- 스펙 폴더를 만들었다.

## 2026-11-04 설계 다시 정함 (B 방식)
- 사용자 결정: 상세 화면은 `popupUuid`만 받아 직접 불러온다 (D-6). 로딩·오류 화면(D-8), `PopupDetail` 모델(D-7), 탭 신호 유지(D-9), D-2·D-5 추천안 확정
- 대체: D-3(`userUuid` 남김), D-4(하트 뒤 늦은 응답) → D-6
- 바뀐 요구사항: R1, R6, 새 R8
- 코드 확인: 상세 진입 8곳이 MainTab의 `appendPopupDetail` 두 함수를 거친다. 2026-10-30 이후 상세 코드 변경 없음
- 승인: 설계 (2026-11-04) — "추천대로 진행해줘"
- 상태 변경: 설계 승인 대기 → 스펙 승인 대기

## 2026-11-04 스펙 승인과 체크리스트 작성
- 승인: 테크 스펙 (2026-11-04) — "승인 이슈도 만들어줘" (AI가 정한 세부 1~6 포함)
- 이슈 #140 "[feature] 팝업 상세 화면이 popupUuid로 직접 불러오도록 V2로 전환한다", 브랜치 `feature/#140` (자동 생성)
- 체크리스트 S01~S05 작성. 순서: `userUuid`가 필요한 V1 호출(관련 팝업·찜·비활성화)을 먼저 V2로 옮긴 뒤(S01·S02) 상세를 `popupUuid` 방식으로 바꾼다(S04)
- 상태 변경: 스펙 승인 대기 → 체크리스트 승인 대기

## 2026-11-04 체크리스트 승인
- 승인: 체크리스트 (2026-11-04) — "승인 S01 진행해줘"
- 상태 변경: 체크리스트 승인 대기 → 구현 중

## 2026-11-04 S01 조회 기록과 관련 팝업을 V2로 전환
- 시작 커밋: `453d17e` (`feature/#140`), 작업 트리: 스펙 폴더만 추적 안 됨
- 바꾼 파일: `Data/Sources/Remote/V2PopupAPI.swift` (`view`, `related` 추가), `PopupAPI.swift` (V1 `increaseViewCount`, `getPersonalRelatedPopupList` 삭제), `RepositoryImpl/PopupRepositoryImpl.swift`, Domain `PopupRepositoryProtocol`·`PopupUsecaseProtocol`·`PopupUsecaseImpl` (`getPersonalRelatedPopupList(userUuid:popupUuid:)` → `getRelatedPopupList(popupUuid:)`), `PopupDetailFeature` client·reducer·Demo, `Data/Tests/PopupRepositoryTests.swift`, `Data/Tests/DataTests.swift`
- 판단: 조회 기록도 `popupRequest {}`로 감싸 실패를 `PopupError.failed`로 바꿈. 상세 화면은 지금처럼 `errorMessage`에만 넣으므로 동작은 같음
- 바꾼 테스트와 이유: `DataTests.swift`의 V1 경로·메서드 확인 4줄 삭제 — 해당 V1 case를 지웠고, 같은 내용을 V2 테스트로 옮김
- 완료 조건:
  - `xcodebuild test … -scheme Data -only-testing:DataTests/PopupRepositoryTests` → 통과 (13 tests, 새 S01 6개 포함)
  - `xcodebuild test … -scheme Data` → 통과 (89 tests in 7 suites)
  - `xcodebuild build … -scheme PopPangApp` → BUILD SUCCEEDED
- 결과: 완료 ([x])

## 2026-11-04 S02 찜과 관리자 비활성화를 V2로 전환
- 시작 상태: `feature/#140` `453d17e` + S01 변경(커밋 전)
- 바꾼 파일: `Data/Sources/Remote/V2AdminAPI.swift` (새 파일), `AdminAPI.swift` (V1 `deactivatePopup` 삭제), `RepositoryImpl/AdminRepositoryImpl.swift` (provider 주입, `deactivatePopup(popupUuid:)`), Domain `AdminRepositoryProtocol`·`AdminUsecaseProtocol`·`AdminUsecaseImpl`, `PopupDetailFeature` client(찜·비활성화 인자에서 `userUuid`/`adminUuid` 제거)·reducer·Demo, `Data/Tests/AdminRepositoryTests.swift` (새 파일), `Data/Tests/DataTests.swift`
- 판단: `AdminRepositoryImpl(makeV2Provider:)`에 기본값을 둬서 `App/Sources/AppCore/1. AppDependencyRegistry.swift`는 바꾸지 않음 (체크리스트의 예상 파일과 다름)
- 판단: 비활성화 실패(403 권한 없음 포함)는 `PopupError.failed`로 바꾸고, `AuthSessionError`·취소는 그대로 던짐. 상세 화면은 지금처럼 `errorMessage`에만 넣음
- 판단: 하트는 #132의 `addFavorite(popupUuid:)`·`removeFavorite(popupUuid:)`를 씀. V1 `addFavorite(userUuid:popupUuid:)`는 다른 탭이 쓰므로 남김
- 바꾼 테스트와 이유: `DataTests.swift`의 V1 `AdminAPI.deactivatePopup` 경로·메서드·query 확인 3곳 삭제 — case를 지웠고 `AdminRepositoryTests`로 옮김
- 완료 조건:
  - `xcodebuild test … -scheme Data -only-testing:DataTests/AdminRepositoryTests` → 통과 (4 tests)
  - `xcodebuild test … -scheme Data` → 통과 (93 tests in 8 suites)
  - `xcodebuild build … -scheme PopPangApp` → BUILD SUCCEEDED
- 결과: 완료 ([x])

## 2026-11-04 S03 상세 단건 조회 API와 `PopupDetail` 모델
- 시작 상태: `feature/#140` `453d17e` + S01·S02 변경(커밋 전)
- 바꾼 파일: `Domain/Sources/Entities/PopupDetail.swift` (새 파일), `PopupError.swift` (`notFound`), `Data/Sources/DTO/PopupDetailDTO.swift` (새 파일), `PopupDTO.swift` (`PopupFieldMapping`으로 변환 규칙 모음), `Remote/V2PopupAPI.swift` (`detail`), `RepositoryImpl/PopupRepositoryImpl.swift` (`getPopupDetail`, `popupRequest`의 404 4301 → `notFound`), Domain Popup repository·usecase protocol과 구현, `Data/Tests/PopupRepositoryTests.swift`
- 판단: 이미지 주소·도로명 주소·미디어 종류 변환을 `PopupFieldMapping`에 모아 목록과 상세가 같은 기준을 쓰게 함. `PopupDTO` 동작은 같음 (기존 테스트 통과)
- 판단: 404 4301 변환을 `popupRequest`에 둠. 4301은 "없는 팝업"이라 관련 팝업 등 다른 V2 팝업 요청에서도 같은 뜻이다. 찜 없음(404 4102)은 지금처럼 `failed`
- 판단: `PopupDetail.mediaType`은 `Popup.MediaType`을 그대로 씀
- 완료 조건:
  - `xcodebuild test … -scheme Data -only-testing:DataTests/PopupRepositoryTests` → 통과 (19 tests, 새 S03 6개 포함. 그 밖 실패는 인자 2개)
  - `xcodebuild test … -scheme Data` → 통과 (99 tests in 8 suites)
  - 추가 확인: `xcodebuild build … -scheme PopPangApp` → BUILD SUCCEEDED (`PopupError`에 case가 늘어 앱 전체 빌드 확인)
- 결과: 완료 ([x])

## 2026-11-04 S04 상세 화면을 `popupUuid`로 열고 직접 불러오기
- 시작 상태: `feature/#140` `453d17e` + S01~S03 변경(커밋 전)
- 바꾼 파일:
  - `PopupDetailFeature/Sources/Presentation/PopupDetailFeature.swift`: State를 `popupUuid`·`detailState`(`loading`·`loaded(PopupDetail)`·`failed(LoadFailure)`)로 바꾸고 `userUuid`·`popup` 삭제. `onAppear`에서 상세·조회 기록·관련 팝업을 따로 보냄. `retryTapped`는 `.failed(.failed)`일 때 상세만 다시 받음. 하트·비활성화는 `loaded`일 때만
  - `PopupDetailFeatureView.swift`: 로딩(`ProgressView`), 오류 화면(찾을 수 없음 + 뒤로 가기, 실패 + 다시 시도), 하위 화면이 `PopupDetail`을 씀, `onSelectRelatedPopup`이 `popupUuid`만 넘김. 사진 위 그림자(`topShadowGradient`)는 내용 화면에만
  - `PopupDetailClient.swift`: `getPopupDetail` 추가
  - `Resources/Localizable.xcstrings`: 새 문구 4개(ko·en·ja, en·ja needs_review). 기존 형식을 바꾸지 않고 추가만 함
  - `Demo/Sources/PopupDetailFeatureDemoApp.swift`: `-demoDetail notFound|failed`, 1초 로딩, 실패 모드는 두 번째 요청부터 성공
  - `Project.swift`: `PopupDetailFeatureTests` 타깃, `PopupDetailFeatureDemo` scheme (데모 scheme이 없어 빌드할 수 없었음)
  - `Tests/PopupDetailFeatureTests.swift` (새 파일, 7 tests)
  - `MainTabFeature/Sources/MainTabFeature.swift`: `appendPopupDetail(popupUuid:)` 두 곳, `PopupDetailDestinationFeature.State(popupUuid:isAdmin:hidesSystemTabBar:)`, `relatedPopupSelected(popupUuid:)`, `pushPopupDetail(popupUuid:)`. 탭의 `popupSelected(Popup)`는 그대로(D-9)
  - `MainTabFeatureView.swift`: 관련 팝업 콜백, `MainTabFeature/Tests/MainTabFeatureTests.swift`
- 체크리스트 예상과 다른 점: `MainTabFeatureDependencies.swift`는 `PopupDetailClient.live`의 인자가 그대로라 바꾸지 않음. `Project.swift`에 데모 scheme을 더함
- 바꾼 테스트와 이유: `searchDestinationPushesPopupDetail` — 상세 진입 State가 `popupUuid`만 받도록 바뀜(D-6). 새 테스트 `tabPopupSelectionPushesDetailWithPopupUuid`
- 테스트 중 고친 것: 첫 테스트가 세 응답의 도착 순서를 고정해 실패 → 끝난 뒤 상태를 보도록 바꿈(`skipReceivedActions(strict: false)`)
- 완료 조건:
  - `xcodebuild test … -scheme PopupDetailFeature -only-testing:PopupDetailFeatureTests` → 통과 (7 tests)
  - `xcodebuild test … -scheme MainTabFeature -only-testing:MainTabFeatureTests` → 통과 (7 tests)
  - `rg -n "userUuid" Projects/Features/PopupDetailFeature/Sources` → 결과 없음
  - `xcodebuild build … -scheme PopPangApp` → BUILD SUCCEEDED
  - 추가 확인: `xcodebuild build … -scheme PopupDetailFeatureDemo` → BUILD SUCCEEDED. iPhone SE 데모 캡처로 로딩 → 내용, 찾을 수 없음, 다시 시도 화면 확인
- 확인 필요: 데모 앱에 한국어 지역화(`CFBundleLocalizations`)가 없어 문구가 영어로 보임 (AuthFeatureV2 데모와 같은 문제)
- 결과: 완료 ([x])

## 2026-11-04 S05 진행 중 (실제 서버 확인 대기)
- 사용자 요청: "S05 진행해줘 한국어 설정도 같이"
- 바꾼 파일: `PopupDetailFeature/Project.swift` (데모 `CFBundleLocalizations` ko·en·ja), `Docs/architecture/api-v2-migration.md` (3번 완료, "팝업 상세 (#140)" 절, 관리자 비활성화 확인 필요 항목 삭제), `Docs/development/testing.md` (Data 8파일 99개, MainTab 7개, `PopupDetailFeatureTests` 7개, 실행 명령), `Docs/architecture/architecture.md` (PopupDetailFeature 행에 테스트 타깃)
- 확인:
  - `xcodebuild build … -scheme PopupDetailFeatureDemo` → BUILD SUCCEEDED
  - iPhone SE 데모 캡처: 내용 화면, "팝업을 찾을 수 없어요" + 뒤로 가기, "팝업을 불러오지 못했어요" + 다시 시도가 한국어로 보임 (완료 조건 2번)
  - `rg -n "getPersonalRelatedPopupList|deactivatePopup\(adminUuid" Projects` → 결과 없음 (완료 조건 3번)
  - `api-v2-migration.md` 3번 행 → 완료 (완료 조건 4번)
- 남은 것: 실제 서버 확인 (완료 조건 1번). iPhone 16 Pro 시뮬레이터에 새 앱을 설치했지만 로그인 전(온보딩) 상태라 소셜 로그인이 필요함 → 사용자 확인 대기
- 결과: 미완료 ([ ])

## 2026-11-04 S05 실제 서버 확인 완료
- 사용자 확인 (2026-11-04): "확인했어 문제없어" — 로그인한 앱에서 실제 서버로 상세 진입(로딩 → 내용), 하트 유지, 관련 팝업 이동 확인 (완료 조건 1번)
- 결과: 완료 ([x])
- 상태 변경: 모든 단계 완료 → 완료
