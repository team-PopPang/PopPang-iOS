# 찜 화면 V2 API 전환 진행 기록

- 스펙: [spec.md](spec.md) · 체크리스트: [tasks.md](tasks.md)

<!-- 덧붙이기만 한다. 이전 기록은 고치지 않는다. -->

## 2026-10-27 시작

- 스펙 폴더를 만들었다.

## 2026-10-28

- 승인: 설계 (2026-10-28) — 사용자 "설계 승인". D-2 확장, D-3, D-4, A-2 포함
- 승인: 테크 스펙 (2026-10-28) — 사용자 "스펙 승인"
- 체크리스트 S01~S03을 쓰고 check를 통과했다.
- 승인: 체크리스트 (2026-10-28) — 사용자 "체크리스트 승인". S01은 #131 병합 뒤 시작(H-1)

## 2026-10-28 S01 시작 중 단계 변경

- 시작: 167954d (`refactor/#132`, main에서 생성). 관련 없는 변경: `.obsidian/` (건드리지 않음)
- 이슈 #132를 만들었다.
- 막힌 점: S01이 `FavoritesFeature.State.userUuid`를 지우면, S02 전까지 V1인 하트 토글이 `userUuid`를 못 받아 빌드가 깨진다. 체크리스트를 쓸 때 놓쳤다.
- 바뀐 단계: S01과 S02를 S01 하나로 합쳤다. S02는 없어지고 S03은 번호를 유지한다. 결정(D-1~D-4)과 요구사항은 그대로다.
- 정한 사람: 사용자 (2026-10-28, "B안으로 하자"). 검토한 대안: A안(`userUuid` 제거만 S02로 옮김, 추천했음)
- 합치기 전에 이미 한 일: `V2FavoriteAPI.swift`(`.list`), Domain·Data `getFavoriteList()`, V1 `.getFavoriteList` 삭제와 DataTests 두 줄 삭제

## 2026-10-28 S01 찜 목록과 하트 토글을 V2로 바꾸고 찜 탭에서 userUuid 빼기

- 시작: 167954d (`refactor/#132`). 관련 없는 변경: `.obsidian/` (건드리지 않음)
- 바꾼 파일: `V2FavoriteAPI.swift`(새 파일), `PopupAPI.swift`, `PopupRepositoryImpl.swift`, `PopupRepositoryProtocol.swift`, `PopupUsecaseProtocol.swift`, `PopupUsecaseImpl.swift`, `FavoritesFeatureClient.swift`, `FavoritesFeature.swift`, FavoritesFeature `Localizable.xcstrings`, `FavoritesFeatureDemoApp.swift`, `MainTabFeature.swift`, `FavoriteRepositoryTests.swift`(새 파일), `PopupRepositoryTests.swift`, `DataTests.swift`
- 완료 조건:
  - `mise exec -- tuist test Data` → 통과 (77 tests, 0 failures. `FavoriteRepositoryTests` 7개 포함)
  - `rg -n "favorite/popup/" Projects --glob '*.swift'` → 결과 없음
  - `rg -n "userUuid" Projects/Features/FavoritesFeature` → 결과 없음
  - `xcodebuild build ... -scheme PopPangApp` → BUILD SUCCEEDED
  - `xcodebuild test ... -scheme MainTabFeature -only-testing:MainTabFeatureTests` → 통과 (6 tests)
  - `xcodebuild test ... -scheme HomeFeatureV2 -only-testing:HomeFeatureV2Tests` → 통과 (8 tests)
  - 확인할 동작: 시뮬레이터 찜 탭 목록과 하트 해제 → 실행하지 못함. 이 환경에서 시뮬레이터 화면을 누를 수 없다. 사용자 확인 필요
- 판단: `PopupRepositoryTests`의 테스트 도구를 찜 테스트와 함께 쓰려고 `private`을 풀고 `PopupFixture`·`PopupTestStore`·`PopupRepositoryContext`로 이름을 바꿨다 — 다른 테스트 파일의 `private` 같은 이름과 겹쳐서 — 틀리면 도구를 파일마다 복사하면 됨
- 판단: `HeaderRecorder`가 헤더 대신 요청 전체를 기록하게 했다 — 등록·해제의 메서드 확인에 필요 — 기존 검색 테스트의 `authorizationHeaders`는 그대로 쓸 수 있음
- 판단: `popupRequest {}` 로그 문구를 "팝업 조회 실패"에서 "팝업 요청 실패"로 바꿨다 — 찜 등록·해제에도 쓰여서 — 로그 문구뿐임
- 판단: 하트 실패 때 목록을 먼저 다시 받고 그다음 안내 문구를 넣는다 — `favoritePopupsLoaded`가 `errorMessage`를 지우므로 순서를 바꾸면 문구가 사라진다 — 순서만 바꾸면 됨
- 결과: 미완료 ([ ]). 시뮬레이터 동작 확인만 남음

## 2026-10-28 S01 시뮬레이터 확인

- 확인할 동작: 시뮬레이터 찜 탭 목록과 하트 해제 → 사용자 확인함 ("시뮬레이터 확인했어")
- 결과: 완료 ([x])

## 2026-10-28 S03 전환 문서 갱신과 전체 검증

- 시작: 473113e. 관련 없는 변경: `.obsidian/` (건드리지 않음). 스펙 폴더의 S01 완료 표시는 커밋 전
- 바꾼 파일: `Docs/architecture/api-v2-migration.md`, `Docs/development/testing.md`
- 완료 조건:
  - `rg -n "FavoritesFeature" Docs/architecture/api-v2-migration.md` → 2번 행 "진행 중 (#132)"
  - `mise exec -- tuist test Core` → 통과 (51 tests: 50 passed, 1 skipped. 건너뜀은 기존 Keychain 테스트)
  - `mise exec -- tuist test Data` → "no tests to run, finishing early"로 0개 실행. 통과로 보지 않았다. Data 코드가 S01 뒤로 바뀌지 않아 Tuist가 건너뛴 것으로 보인다
  - 대신 `xcodebuild test -workspace PopPang.xcworkspace -scheme Data -destination <sim>` → 통과 (77 tests in 7 suites). `testing.md`의 7개 파일·77개와 같다
  - 확인할 동작: 실제 계정으로 빈 목록, 다른 기기에서 해제한 팝업의 하트 → 사용자 확인 필요. 목록과 하트 해제는 S01에서 사용자가 확인함
- 판단: 전환 문서 1번 행(SearchFeature)도 "진행 중 (#130)"에서 "완료 (#131)"로 고쳤다 — #131이 병합돼 문서가 실제와 달랐다 — 문서 한 줄뿐임
- 판단: 전환 문서에 찜 V2 API 위치, 뒤 화면이 쓸 함수 이름, 실패 처리 원칙을 적었다 — 할 일의 "뒤의 feature가 가져다 쓴다"를 구체적으로 — 문서뿐임
- 결과: 미완료 ([ ]). 직접 확인할 동작만 남음

## 2026-10-28 S03 직접 확인

- 확인할 동작: 빈 목록, 다른 기기에서 해제한 팝업의 하트 → 사용자 확인함 ("확인했어")
- 결과: 완료 ([x]). 모든 단계가 끝나 스펙 상태를 완료로 바꿨다

## 2026-10-28 push 전 리뷰 FAIL 대응

- 리뷰 판정: FAIL. 근거는 (1) 하트가 로그인 끊김·취소로 실패해도 목록을 다시 받아 "다시 로그인 필요" 알림이 두 번 감 (2) 하트를 빠르게 두 번 누르면 두 번째 DELETE가 404 4102를 받아 해제가 됐는데도 실패 문구가 뜸
- 바뀐 결정: D-5 추가 (찜 해제를 낙관적으로 반영). 사용자 "낙관적으로 진행" (2026-10-28)
- 고친 것: `FavoritesFeature.swift`(먼저 빼기, 성공 뒤 다시 받기 없음, `AuthSessionError`는 문구만, 취소는 무시, 목록 조회 취소도 문구 없음), `PopupRepositoryTests.swift`·`FavoriteRepositoryTests.swift`(`HeaderRecorder` → `RequestRecorder`, `URLRequest`가 없는 요청도 `nil`로 기록), `Docs/architecture/api-v2-migration.md` 한 줄
- 그대로 둔 지적: 목록을 다시 받은 뒤에도 문구를 남김(1차 답 A), 찜 탭 테스트 타깃 없음(A-2), 같은 이름의 V2 함수와 `PopupRepository` 안 배치(D-4), `isFavorited`로 등록·해제 고르기(기존 동작)
- 확인:
  - `xcodebuild test ... -scheme Data` → 통과 (77 tests in 7 suites)
  - `xcodebuild build ... -scheme PopPangApp` → BUILD SUCCEEDED
  - `MainTabFeatureTests` 6개, `HomeFeatureV2Tests` 8개 통과
  - 낙관적 해제의 화면 동작 → 사용자 확인 필요 (S01·S03 확인은 이 수정 전에 했다)

## 2026-10-28 두 번째 리뷰 FAIL 대응

- 리뷰 판정: FAIL. 근거는 진행 중인 목록 응답이나 실패 뒤 다시 받은 목록이 먼저 뺀 팝업을 되살림
- 바뀐 결정: D-6 추가, D-5는 대체됨. R2를 찜 탭 해제 전용으로 좁힘. 사용자 "Set으로, A로 진행" (2026-10-28)
- 고친 것: `FavoritesFeature.swift`(서버 목록 `loadedPopups`, 해제 중·해제 완료 Set, `removeFavoriteFinished` action, 목록 요청 `cancelInFlight`, 목록 응답이 문구를 지우지 않음, 실행되지 않던 취소 분기와 등록 분기 삭제), `FavoritesFeatureClient.swift`·Demo(`addFavorite` 삭제), `Docs/architecture/api-v2-migration.md` 한 줄
- 그대로 둔 지적: 404 4102에도 안내 문구(1차 답 A), 찜 탭 테스트 타깃 없음(A-2)
- 확인: `xcodebuild build ... -scheme PopPangApp` → BUILD SUCCEEDED, `-scheme FavoritesFeature` 빌드 성공, Data 77개·MainTab 6개·HomeFeatureV2 8개 통과
- 확인 못 함: FavoritesFeatureDemo는 워크스페이스에 스킴이 없어 빌드하지 않았다(Demo는 `addFavorite: { _ in },` 한 줄만 지움). 바뀐 하트 동작의 화면 확인은 사용자 확인 필요
