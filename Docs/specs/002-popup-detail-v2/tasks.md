# 팝업 상세 화면 V2 전환 개발 순서와 체크리스트

- 스펙: [spec.md](spec.md) · 진행 기록: [log.md](log.md)

<!-- 단계 목록의 체크박스가 진행 상태의 기준이다. [x]만 완료로 센다. -->

## 단계 목록

- [x] S01 조회 기록과 관련 팝업을 V2로 전환
- [x] S02 찜과 관리자 비활성화를 V2로 전환
- [x] S03 상세 단건 조회 API와 `PopupDetail` 모델
- [x] S04 상세 화면을 `popupUuid`로 열고 직접 불러오기
- [x] S05 시뮬레이터 확인과 문서 갱신

## S01 조회 기록과 관련 팝업을 V2로 전환
- 요구사항: R3, R4
- 결정: D-2
- 할 일:
  - `V2PopupAPI`에 조회 기록(`POST /popup/{popupUuid}/view`)과 관련 팝업(`GET /user/popups/{popupUuid}/related`)을 추가한다. Access Token을 쓴다.
  - `increaseViewCount(popupUuid:)`는 경로만 V2로, `getPersonalRelatedPopupList(userUuid:popupUuid:)`는 `getRelatedPopupList(popupUuid:)`로 바꾼다 (Repository·Usecase·protocol). `popupRequest {}`로 실패를 바꾼다.
  - `PopupDetailClient`의 관련 팝업 함수에서 `userUuid`를 뺀다. 화면 동작은 바꾸지 않는다.
  - `PopupAPI`의 V1 case 두 개를 지운다.
- 바꿀 파일:
  - `Projects/Data/Sources/Remote/V2PopupAPI.swift`, `PopupAPI.swift`
  - `Projects/Data/Sources/RepositoryImpl/PopupRepositoryImpl.swift`
  - `Projects/Domain/Sources/RepositoryProtocol/PopupRepositoryProtocol.swift`, `Usecase/Protocols/PopupUsecaseProtocol.swift`, `Usecase/Implementations/PopupUsecaseImpl.swift`
  - `Projects/Features/PopupDetailFeature/Sources/Dependency/PopupDetailClient.swift`, `Presentation/PopupDetailFeature.swift`
  - `Projects/Data/Tests/PopupRepositoryTests.swift`
- 완료 조건:
  - `xcodebuild test -workspace PopPang.xcworkspace -scheme Data -destination 'id=<시뮬레이터 UDID>' -only-testing:DataTests/PopupRepositoryTests` → 기대: 새 S01 테스트(조회 기록·관련 팝업의 경로·메서드·Access Token·응답·실패 변환) 포함 통과
  - `xcodebuild test -workspace PopPang.xcworkspace -scheme Data -destination 'id=<시뮬레이터 UDID>'` → 기대: Data 전체 통과
  - `xcodebuild build -workspace PopPang.xcworkspace -scheme PopPangApp -destination 'id=<시뮬레이터 UDID>'` → 기대: BUILD SUCCEEDED

## S02 찜과 관리자 비활성화를 V2로 전환
- 요구사항: R5, R7
- 결정: D-2, D-5
- 할 일:
  - 상세 하트가 `addFavorite(popupUuid:)`·`removeFavorite(popupUuid:)`(#132)를 쓰게 `PopupDetailClient`를 바꾼다.
  - 새 `V2AdminAPI`에 비활성화(`PATCH /admin/popup/{popupUuid}/deactivate`, query 없음)를 둔다.
  - `AdminRepositoryImpl`이 provider를 주입받게 하고, `deactivatePopup(adminUuid:popupUuid:)`를 `deactivatePopup(popupUuid:)`로 바꾼다. `AdminAPI`의 V1 case를 지운다.
  - 새 `AdminRepositoryTests`를 만든다.
- 바꿀 파일:
  - `Projects/Data/Sources/Remote/V2AdminAPI.swift` (새 파일), `AdminAPI.swift`
  - `Projects/Data/Sources/RepositoryImpl/AdminRepositoryImpl.swift`
  - `Projects/Domain/Sources/RepositoryProtocol/AdminRepositoryProtocol.swift`, `Usecase/Protocols/AdminUsecaseProtocol.swift`, `Usecase/Implementations/AdminUsecaseImpl.swift`
  - `Projects/App/Sources/AppCore/1. AppDependencyRegistry.swift`
  - `Projects/Features/PopupDetailFeature/Sources/Dependency/PopupDetailClient.swift`, `Presentation/PopupDetailFeature.swift`
  - `Projects/Data/Tests/AdminRepositoryTests.swift` (새 파일)
- 완료 조건:
  - `xcodebuild test -workspace PopPang.xcworkspace -scheme Data -destination 'id=<시뮬레이터 UDID>' -only-testing:DataTests/AdminRepositoryTests` → 기대: 비활성화의 경로·PATCH·query 없음·Access Token·실패 변환 테스트 통과
  - `xcodebuild test -workspace PopPang.xcworkspace -scheme Data -destination 'id=<시뮬레이터 UDID>'` → 기대: Data 전체 통과
  - `xcodebuild build -workspace PopPang.xcworkspace -scheme PopPangApp -destination 'id=<시뮬레이터 UDID>'` → 기대: BUILD SUCCEEDED

## S03 상세 단건 조회 API와 `PopupDetail` 모델
- 요구사항: R2, R6
- 결정: D-7
- 할 일:
  - Domain에 `PopupDetail`을 만들고, `PopupError`에 `notFound`를 더한다.
  - Data에 `PopupDetailDTO`를 만든다. null 처리는 `PopupDTO`와 같다.
  - `V2PopupAPI`에 단건 조회(`GET /user/popups/{popupUuid}`)를 더하고 `getPopupDetail(popupUuid:) -> PopupDetail`을 Repository·Usecase에 추가한다. 404 4301은 `PopupError.notFound`로 바꾼다.
- 바꿀 파일:
  - `Projects/Domain/Sources/Entities/PopupDetail.swift` (새 파일), `PopupError.swift`
  - `Projects/Data/Sources/DTO/PopupDetailDTO.swift` (새 파일)
  - `Projects/Data/Sources/Remote/V2PopupAPI.swift`, `RepositoryImpl/PopupRepositoryImpl.swift`
  - Domain Popup repository·usecase protocol과 구현
  - `Projects/Data/Tests/PopupRepositoryTests.swift`
- 완료 조건:
  - `xcodebuild test -workspace PopPang.xcworkspace -scheme Data -destination 'id=<시뮬레이터 UDID>' -only-testing:DataTests/PopupRepositoryTests` → 기대: 새 S03 테스트(단건 경로·Access Token·`isFavorited` 포함 디코딩·null 필드·404 4301 → `notFound`·그 밖 → `failed`) 포함 통과
  - `xcodebuild test -workspace PopPang.xcworkspace -scheme Data -destination 'id=<시뮬레이터 UDID>'` → 기대: Data 전체 통과

## S04 상세 화면을 `popupUuid`로 열고 직접 불러오기
- 요구사항: R1, R2, R6, R8
- 결정: D-6, D-8, D-9
- 할 일:
  - `PopupDetailFeature.State`를 `popupUuid`·`detailState`로 바꾸고 `userUuid`·`popup`을 지운다. `onAppear`에서 상세·조회 기록·관련 팝업을 따로 보낸다. 다시 시도는 상세만 다시 받는다.
  - 화면: 로딩 표시, 오류 화면(찾을 수 없음 + 뒤로 가기, 실패 + 다시 시도). 불러온 뒤 배치는 그대로. 새 문구 ko·en·ja.
  - 하트·공유·비활성화는 `loaded`일 때만 동작한다.
  - MainTab: `PopupDetailDestinationFeature.State(popupUuid:…)`, `appendPopupDetail`이 `popup.popupUuid`만 넘김, `pushPopupDetail(popupUuid:)`. 탭의 `popupSelected(Popup)`는 그대로.
  - 새 `PopupDetailFeatureTests` 타깃(Tuist)과 Demo 가짜 client(성공·없음·실패).
- 바꿀 파일:
  - `Projects/Features/PopupDetailFeature/Sources/**`, `Resources/Localizable.xcstrings`, `Demo/Sources/PopupDetailFeatureDemoApp.swift`, `Project.swift`
  - `Projects/Features/PopupDetailFeature/Tests/PopupDetailFeatureTests.swift` (새 파일)
  - `Projects/Features/MainTabFeature/Sources/MainTabFeature.swift`, `MainTabFeatureView.swift`, `MainTabFeatureDependencies.swift`, `Tests/MainTabFeatureTests.swift`
- 완료 조건:
  - `xcodebuild test -workspace PopPang.xcworkspace -scheme PopupDetailFeature -destination 'id=<시뮬레이터 UDID>' -only-testing:PopupDetailFeatureTests` → 기대: 로딩 → 내용, 404 → 찾을 수 없음, 실패 → 다시 시도 → 내용, 관련 팝업 실패에도 내용, 하트, 비활성화 테스트 통과
  - `xcodebuild test -workspace PopPang.xcworkspace -scheme MainTabFeature -destination 'id=<시뮬레이터 UDID>' -only-testing:MainTabFeatureTests` → 기대: 상세 진입이 `popupUuid`만 넘기는 테스트 포함 통과
  - `rg -n "userUuid" Projects/Features/PopupDetailFeature/Sources` → 기대: 결과 없음
  - `xcodebuild build -workspace PopPang.xcworkspace -scheme PopPangApp -destination 'id=<시뮬레이터 UDID>'` → 기대: BUILD SUCCEEDED

## S05 시뮬레이터 확인과 문서 갱신
- 요구사항: R1, R2, R3, R4, R5, R6, R7, R8
- 할 일:
  - 앱을 실제 서버로 실행해 홈·지도·캘린더·찜·알림·검색에서 상세를 열어 본다.
  - `api-v2-migration.md` 3번을 완료로 바꾸고 상세 V2 내용을 적는다. `testing.md`에 새 테스트 타깃과 수를 적는다. `architecture.md`의 모듈 설명이 달라지면 고친다.
- 바꿀 파일:
  - `Docs/architecture/api-v2-migration.md`, `Docs/development/testing.md`
- 완료 조건:
  - 확인할 동작: 실제 서버에서 상세 진입 시 로딩 뒤 내용이 나오고, 하트가 바뀌고 다시 열어도 유지되고, 관련 팝업을 누르면 그 팝업 상세가 열린다
  - 확인할 동작: Demo의 가짜 실패로 "팝업을 찾을 수 없어요"와 "팝업을 불러오지 못했어요" + 다시 시도가 보인다
  - `rg -n "getPersonalRelatedPopupList|deactivatePopup\(adminUuid" Projects` → 기대: 결과 없음
  - `rg -n "\| 3 \| PopupDetailFeature" Docs/architecture/api-v2-migration.md` → 기대: 상태가 완료
