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
