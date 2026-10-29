# 찜 화면 V2 API 전환 개발 순서와 체크리스트

- 스펙: [spec.md](spec.md) · 진행 기록: [log.md](log.md)

<!-- 단계 목록의 체크박스가 진행 상태의 기준이다. [x]만 완료로 센다. -->

## 단계 목록

- [x] S01 찜 목록과 하트 토글을 V2로 바꾸고 찜 탭에서 userUuid 빼기
- [x] S03 전환 문서 갱신과 전체 검증

S02는 S01에 합쳤다(2026-10-28, log.md). 번호는 다시 매기지 않는다.

공통 명령의 `<sim>`은 `id=7AD2920B-36F6-4B7A-B3B9-14DEE96A5F74`다. `xcodebuild` 전에는 `mise exec -- tuist generate --no-open`을 먼저 실행한다.

## S01 찜 목록과 하트 토글을 V2로 바꾸고 찜 탭에서 userUuid 빼기
- 요구사항: R1, R2, R3, R4, R5
- 결정: D-1, D-2, D-3, D-4
- 할 일:
  - #131 병합을 확인하고 main에서 이슈와 `refactor/#<이슈>` 브랜치를 만든다 (H-1).
  - `V2FavoriteAPI`를 새로 만들고 `.list`(`GET /favorite/popup`), `.add(popupUuid:)`(`POST /favorite`), `.remove(popupUuid:)`(`DELETE /favorite`)를 둔다. 모두 `.v2`·`.access`, 등록·해제 본문은 `{"popupUuid"}` JSON.
  - `getFavoriteList(userUuid:)`를 `getFavoriteList()`로 바꾸고 `APIResponse<[PopupDTO]>`의 `data`를 읽는다. V1 `.getFavoriteList` case를 지운다.
  - `addFavorite(popupUuid:)`·`removeFavorite(popupUuid:)`를 Repository·Usecase 프로토콜과 구현에 새로 더한다. 기존 `userUuid` 함수는 그대로 둔다. 세 함수 모두 `popupRequest {}`로 감싼다.
  - `FavoritesFeatureClient` 세 함수에서 `userUuid` 인자를 빼고, `FavoritesFeature.State`에서 `userUuid`를 지운다. `MainTabFeature`는 `.init()`으로 만든다. Demo를 고친다.
  - 목록 실패 문구 "찜한 팝업을 불러오지 못했어요. 잠시 후 다시 시도해 주세요.", 토글 실패 문구 "찜을 바꾸지 못했어요. 잠시 후 다시 시도해 주세요."를 ko·en·ja로 넣는다.
  - `toggleLike`가 실패하면 토글 실패 문구를 보여 주고 목록을 다시 받는다. 다시 받은 목록도 실패하면 문구만 남기고 이전 목록을 둔다.
  - Data 테스트 `FavoriteRepositoryTests`를 만든다: 세 요청의 경로·메서드·Bearer·본문(`popupUuid`만), `data` 디코딩, 빈 `data`, 200 빈 본문, 409 4101·404 4102·500 → `PopupError.failed`, 401 5001 → `AuthSessionError.loginRequired`.
- 바꿀 파일:
  - `Projects/Data/Sources/Remote/V2FavoriteAPI.swift` (새 파일)
  - `Projects/Data/Sources/Remote/PopupAPI.swift`
  - `Projects/Data/Sources/RepositoryImpl/PopupRepositoryImpl.swift`
  - `Projects/Domain/Sources/RepositoryProtocol/PopupRepositoryProtocol.swift`
  - `Projects/Domain/Sources/Usecase/Protocols/PopupUsecaseProtocol.swift`
  - `Projects/Domain/Sources/Usecase/Implementations/PopupUsecaseImpl.swift`
  - `Projects/Features/FavoritesFeature/Sources/Dependency/FavoritesFeatureClient.swift`
  - `Projects/Features/FavoritesFeature/Sources/Presentation/FavoritesFeature.swift`
  - `Projects/Features/FavoritesFeature/Resources/Localizable.xcstrings`
  - `Projects/Features/FavoritesFeature/Demo/Sources/FavoritesFeatureDemoApp.swift`
  - `Projects/Features/MainTabFeature/Sources/MainTabFeature.swift`
  - `Projects/Data/Tests/FavoriteRepositoryTests.swift` (새 파일), `Projects/Data/Tests/PopupRepositoryTests.swift`, `Projects/Data/Tests/DataTests.swift`
- 완료 조건:
  - `mise exec -- tuist test Data` → 기대: `FavoriteRepositoryTests`를 포함해 모두 통과 (이 단계 전에는 테스트 파일이 없어 실패)
  - `rg -n "favorite/popup/" Projects --glob '*.swift'` → 기대: 결과 없음 (V1 목록 경로가 사라짐)
  - `rg -n "userUuid" Projects/Features/FavoritesFeature` → 기대: 결과 없음
  - `xcodebuild build -workspace PopPang.xcworkspace -scheme PopPangApp -destination <sim>` → 기대: BUILD SUCCEEDED
  - `xcodebuild test -workspace PopPang.xcworkspace -scheme MainTabFeature -destination <sim> -only-testing:MainTabFeatureTests` → 기대: 통과
  - `xcodebuild test -workspace PopPang.xcworkspace -scheme HomeFeatureV2 -destination <sim> -only-testing:HomeFeatureV2Tests` → 기대: 통과 (다른 화면의 V1 찜 함수가 그대로임)
  - 확인할 동작: 시뮬레이터 찜 탭에서 목록이 보이고, 하트를 누르면 목록에서 빠진다

## S03 전환 문서 갱신과 전체 검증
- 요구사항: R1, R2, R3
- 할 일:
  - `Docs/architecture/api-v2-migration.md` 표의 2번 상태를 바꾸고, 찜 등록·해제 V2 함수가 생겼으니 뒤의 feature가 가져다 쓴다고 적는다.
  - `Docs/development/testing.md`의 Data 테스트 수를 고친다.
  - 전체 테스트와 빌드를 다시 돌린다.
  - 직접 확인할 동작을 사용자에게 요청한다.
- 바꿀 파일:
  - `Docs/architecture/api-v2-migration.md`
  - `Docs/development/testing.md`
- 완료 조건:
  - `rg -n "FavoritesFeature" Docs/architecture/api-v2-migration.md` → 기대: 2번 행 상태가 "예정"이 아니다
  - `mise exec -- tuist test Core` → 기대: 통과 (건너뜀 1개는 기존)
  - `mise exec -- tuist test Data` → 기대: 통과, 개수가 `testing.md`와 같다
  - 확인할 동작: 실제 계정으로 찜 탭 목록·빈 목록·하트 해제, 다른 기기에서 해제한 팝업의 하트를 누르면 안내 문구 뒤 목록에서 빠진다
