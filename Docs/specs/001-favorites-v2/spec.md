# 찜 화면 V2 API 전환 테크 스펙

- 상태: 완료
- 만든 날: 2026-10-27
- 체크리스트: [tasks.md](tasks.md) · 진행 기록: [log.md](log.md)

<!-- 상태 값: 인터뷰 중 → 설계 승인 대기 → 스펙 승인 대기 → 체크리스트 승인 대기 → 구현 중 → 완료 -->

## 기획 원문

<!-- 받은 기획서·메모·메신저 내용을 고치지 않고 그대로 둔다. -->

> 2번 찜 진행해줘 방금 /global-spec-dev 이스킬 사용해서 계획

2번은 [V2 API 마이그레이션](../../architecture/api-v2-migration.md#남은-작업-feature별-전환)의 feature별 전환 표의 2번 행이다.

> 순서 2 · FavoritesFeature · 찜 목록 (FAV-04), 찜 등록·해제 (FAV-01·02) · 예정

같은 문서의 원칙: 여러 feature가 같이 쓰는 API(찜 등록·해제 등)는 처음 쓰는 feature에서 V2로 만들고, 뒤의 feature는 가져다 쓴다. `userUuid`는 아직 V1인 화면이 쓰므로 마지막 정리 단계에서 지운다. PR은 feature마다 하나다.

## 1. 목표와 범위

<!-- 승인 뒤에는 사용자만 바꾼다. -->

### 왜 하는지

찜 탭이 부르는 V1 API 세 개를 V2로 옮긴다. V2는 `userUuid`를 경로·본문으로 받지 않고 Access Token의 사용자로 처리한다. 다른 사람의 `userUuid`로 찜을 바꿀 수 있던 V1의 구멍이 닫힌다.

### 하는 것

- 찜 탭(`FavoritesFeature`)의 목록 조회, 찜 해제(하트 토글)를 V2로 부른다.
- 찜 등록·해제 V2를 Domain·Data에 새로 만든다. 뒤의 feature가 가져다 쓴다.

### 하지 않는 것

- 다른 feature(상세, 캘린더, 홈, 지도, 알림)의 찜 등록·해제 전환. 각자 차례에 옮긴다.
- 찜 수 조회(FAV-03). 앱에 호출이 없다.
- V1 찜 case와 Usecase의 `userUuid` 인자 삭제. 다른 feature가 아직 쓴다(9번 정리 단계).
- 찜 탭 화면 디자인 변경.

### 성공 기준

- 찜 탭이 V2 API 세 개만 부르고, 요청에 `userUuid`가 없다.
- 찜한 팝업 목록, 빈 목록, 하트 토글이 V1 때와 같게 동작한다.
- 로그인이 끊기면 다른 V2 화면처럼 로그인 화면으로 간다.

### 제약

- feature 하나에 PR 하나. 다른 feature 동작을 바꾸지 않는다.
- 명세 원문을 저장소에 옮기지 않는다(저장소가 공개, 명세는 내부용). 명세 ID와 앱에 필요한 사실만 적는다.
- 승인 전 파일 수정 금지(AGENTS.md Plan-first).
- 구현은 #131이 main에 병합된 뒤 main에서 새 이슈·브랜치로 시작한다. (1차 답)

<!-- 마감, 쓸 수 없는 기술, 호환 조건처럼 기능이 아닌 조건 -->

## 2. 요구사항

<!-- 한 줄에 하나. 번호는 바꾸지 않는다. 예: - **R1** 사용자는 지도에서 영역을 지정해 해도를 내려받는다. -->

- **R1** 찜 탭은 찜한 팝업 목록을 `GET /api/v2/favorite/popup`(FAV-04)으로 받는다.
- **R2** 찜 탭의 하트 토글은 찜 해제를 `DELETE /api/v2/favorite`(FAV-02), 찜 등록을 `POST /api/v2/favorite`(FAV-01)로 보낸다. 본문은 `popupUuid`만 담는다.
- **R3** 찜 탭은 `userUuid`를 받지도 보내지도 않는다.
- **R4** 찜 탭의 오류는 원본 오류 대신 정해 둔 안내 문구로 보여 준다. (1차 답)
- **R5** 하트 토글이 이미 찜함(409 4101)·찜 없음(404 4102)으로 실패하면 안내 문구를 보여 주고 목록을 다시 받는다. (1차 답)

## 3. 현재 코드

<!-- 확인한 사실과 근거 파일. 예: - 지도: MapKit 대신 Mapbox SDK 사용 (`Podfile`) -->

- 찜 탭 흐름: `FavoritesFeature` → `FavoritesFeatureClient` → `PopupUsecase` → `PopupRepositoryImpl` → `PopupAPI`(V1) (`Projects/Features/FavoritesFeature/Sources/`, `Projects/Data/Sources/RepositoryImpl/PopupRepositoryImpl.swift`)
- V1 찜 API: `getFavoriteList(userUuid:)` `GET /favorite/popup/{userUuid}`, `addFavorite`·`removeFavorite` `POST`·`DELETE /favorite` 본문 `{userUuid, popupUuid}` JSON (`Projects/Data/Sources/Remote/PopupAPI.swift:31-33, 73-76, 163`)
- `FavoritesFeature.State`는 `userUuid`를 들고 있고, 목록 조회와 토글에 쓴다. 토글 뒤에는 목록을 다시 받는다 (`FavoritesFeature.swift`)
- 오류는 `error.localizedDescription`을 그대로 화면에 띄운다. V2 서버 오류면 응답 본문이 섞인 문장이 보인다 (`FavoritesFeature.swift`, `FavoritesFeatureView.swift:91`)
- `MainTabFeature`가 `.init(userUuid: user.userUuid)`로 만든다. `MainTabFeature.State.user`가 있어 상세로 넘길 `userUuid`는 MainTab이 이미 안다 (`MainTabFeature.swift:68, 81, 242`)
- `addFavorite`·`removeFavorite` Usecase는 상세, 캘린더, 홈, 오픈 예정 상세, 지도, 알림도 쓴다 (각 feature의 `*Client.swift`)
- `getFavoriteList`는 찜 탭만 쓴다
- FavoritesFeature에는 테스트 타깃이 없다 (`Projects/Features/FavoritesFeature/Project.swift`)
- V2 기반: `BaseAPI`의 `.v2`·`.access`, `asyncRequest(_:decodeDataTo:)`, `asyncRequestVoid`, `AuthSessionError` (`Projects/Shared/Core/Sources/Network/`)
- 검색(#131) 선례: `V2PopupAPI`, `PopupError.failed`, `popupRequest {}`(AuthSessionError·취소는 그대로, 나머지는 로그 후 `PopupError.failed`), `PopupDTO` null 수정. #131은 아직 열려 있다(main 미병합)
- 명세(FAV-04): 응답은 `APIResponse`로 감싼 팝업 배열이다(검색과 다름). 원소 필드는 V1과 같다
- 명세(FAV-01·02): 성공은 200 본문 없음. 이미 찜함 409 4101, 찜 없음 404 4102. 명세는 이 둘을 성공으로 가정하지 말고 기존 오류 처리에 연결하라고 한다

## 4. 설계

### 기술 스택

| 이름 | 버전 | 새로 들이는지 | 결정 |
| --- | --- | --- | --- |
| Swift·TCA·Moya·Swift Testing | 저장소 그대로 | 아니오 | 기존 관례 |

새 라이브러리·Tuist 설정 변경은 없다.

### 구조

```text
FavoritesFeature (State에서 userUuid 제거)
  └ FavoritesFeatureClient  getFavoriteList() / addFavorite(popupUuid) / removeFavorite(popupUuid)
      └ PopupUsecase        새 V2 함수 (기존 userUuid 함수는 다른 feature용으로 유지)
          └ PopupRepositoryImpl  popupRequest {} 로 감쌈 → PopupError.failed / AuthSessionError
              └ V2FavoriteAPI (새 파일)  GET /favorite/popup · POST /favorite · DELETE /favorite
MainTabFeature: favorites = .init()  (상세로 넘길 userUuid는 MainTab의 user에서)
```

- `V2FavoriteAPI`는 `.v2`·`.access`. POST·DELETE 본문은 `{"popupUuid": ...}` JSON이다. V1도 DELETE에 JSON 본문을 보내고 있어 같은 방식(`JSONEncoding.default`)을 쓴다.
- 목록은 `asyncRequest(_:decodeDataTo: [PopupDTO].self)`로 `data`를 읽는다. 등록·해제는 `asyncRequestVoid`.
- 오류 변환은 검색의 `popupRequest {}`를 그대로 쓴다. `AuthSessionError`·취소는 그대로 던지고, 나머지는 HTTP 상태·서버 코드만 로그로 남긴 뒤 `PopupError.failed`.

### 데이터 모델

- 새 entity·DTO 없음. 목록 원소는 기존 `PopupDTO` → `Popup`(V1과 필드가 같다).

### API

| 명세 | 요청 | 성공 응답 | 앱 쪽 함수 |
| --- | --- | --- | --- |
| FAV-04 | `GET /api/v2/favorite/popup` | `APIResponse<[PopupDTO]>` | `getFavoriteList()` |
| FAV-01 | `POST /api/v2/favorite` `{popupUuid}` | 200 본문 없음 | `addFavorite(popupUuid:)` |
| FAV-02 | `DELETE /api/v2/favorite` `{popupUuid}` | 200 본문 없음 | `removeFavorite(popupUuid:)` |

모두 `Authorization: Bearer {accessToken}`.

### 에러·예외 처리

| 상황 | 처리 |
| --- | --- |
| 목록 조회 실패 | "찜한 팝업을 불러오지 못했어요. 잠시 후 다시 시도해 주세요." |
| 하트 토글 실패(409 4101·404 4102 포함) | "찜을 바꾸지 못했어요. 잠시 후 다시 시도해 주세요."를 보여 주고 목록을 다시 받는다 (D-2) |
| 로그인 끊김(`AuthSessionError.loginRequired`) | 같은 안내 문구. 로그인 화면 전환은 AppFeature가 한다 (검색과 같음) |
| 빈 목록 `data: []` | 정상. 기존 빈 화면 |
| 다시 받은 목록도 실패 | 안내 문구만 남기고 이전 목록 유지 |

문구는 FavoritesFeature의 `Localizable.xcstrings`에 ko·en·ja로 넣는다.

### 테스트 방법

- Data 테스트(`Projects/Data/Tests/`): 세 요청의 경로·메서드·Bearer 헤더·본문(`popupUuid`만), `APIResponse` 목록 디코딩, 빈 목록, 409 4101·404 4102·500 → `PopupError.failed`, 401 5001 → `AuthSessionError.loginRequired`.
- 빌드: 앱 전체 빌드, 기존 Data·MainTab·HomeFeatureV2 테스트 통과.
- 직접 확인: 찜 탭 목록, 빈 목록, 하트 해제, 다른 기기에서 해제한 뒤 하트 누르기.

## 5. 결정 기록

<!-- ### D-1 제목 / - 결정: / - 이유: / - 검토한 대안: / - 영향: / - 정한 사람: -->

### D-1 찜 탭 오류 문구
- 결정: 원본 오류 대신 정해 둔 안내 문구 두 개(목록·토글)
- 이유: V2 오류 본문이 화면에 보이지 않게. 검색(#131)과 같은 방식
- 검토한 대안: 원본 오류 문장 유지
- 영향: R4
- 정한 사람: 사용자 (2026-10-27)

### D-2 하트 토글 실패 뒤 목록 다시 받기
- 결정: 토글이 실패하면 이유와 관계없이 안내 문구를 보여 주고 목록을 다시 받는다
- 이유: 409 4101·404 4102는 서버 상태와 화면이 어긋났다는 뜻이라 다시 받아야 맞춰진다(사용자 답). 다른 실패도 다시 받아서 손해가 없고, 오류 코드를 구분할 새 오류 타입이 필요 없다
- 검토한 대안: 4101·4102만 구분해 다시 받기(`PopupError`에 case 추가 필요)
- 영향: R5
- 정한 사람: 409·404 처리는 사용자 (2026-10-27). 모든 실패로 넓힌 것은 AI 제안, 사용자 확인 (2026-10-28 설계 승인)

### D-3 V2 찜 API 위치
- 결정: 새 파일 `Data/Sources/Remote/V2FavoriteAPI.swift`
- 이유: 경로가 `/favorite`로 회원 팝업(`/user/popups`, `V2PopupAPI`)과 다르고, 명세도 다른 묶음(F)이다. 응답 래퍼도 다르다
- 검토한 대안: `V2PopupAPI`에 case 추가(파일 하나지만 문서 주석의 "감싸지 않은 배열" 설명과 어긋남)
- 영향: R1, R2
- 정한 사람: AI 제안, 사용자 확인 (2026-10-28 설계 승인)

### D-4 Domain 함수 모양
- 결정: `getFavoriteList(userUuid:)`는 `getFavoriteList()`로 바꾼다(찜 탭만 씀). 등록·해제는 `addFavorite(popupUuid:)`·`removeFavorite(popupUuid:)`를 `PopupRepositoryProtocol`·`PopupUsecaseProtocol`에 새로 더하고 기존 `userUuid` 함수는 둔다
- 이유: 기존 함수를 바꾸면 아직 V1인 다섯 feature가 같이 바뀐다. 전환 문서의 "처음 쓰는 feature에서 V2로 만들고 뒤의 feature가 가져다 쓴다" 원칙
- 검토한 대안: 새 `FavoriteRepository` 분리(찜이 지금 Popup 저장소에 있어 이번 범위에 비해 큼)
- 영향: R1, R2, R3
- 정한 사람: AI 제안, 사용자 확인 (2026-10-28 설계 승인)

## 6. 가정과 보류

### 가정

<!-- - **A-1** 내용 (확인할 사람·시점) -->

- **A-1** 찜 등록·해제 V2는 기존 함수를 바꾸지 않고 새 함수로 더한다. D-4로 옮겼다. 확인함 (2026-10-28)
- **A-2** 자동 테스트는 검색(#131)처럼 Data 테스트(요청 형식·디코딩·오류 변환)로 하고, FavoritesFeature 테스트 타깃은 새로 만들지 않는다. Tuist 설정 변경이 필요해서다. 확인함 (2026-10-28)

### 보류

<!-- - **H-1** 내용 (막는 단계) -->

- **H-1** #131 병합 대기. 구현 첫 단계(이슈·브랜치 생성)를 막는다.

## 7. 위험

<!-- - [위험] → 대응 -->

- [DELETE 본문이 전송되지 않음] → V1이 같은 방식으로 이미 보낸다. Data 테스트에서 요청 본문을 직접 확인한다.
- [V1·V2 함수가 같은 이름으로 공존해 잘못 고를 수 있음] → 인자 이름이 다르고(`userUuid` 유무), 정리 단계(9번)에서 V1을 지운다.
- [찜 탭과 다른 화면이 V1·V2로 섞임] → 서버 데이터가 같아 괜찮다(명세 C-9).

## 8. 질문과 답

### 분야별 상태

| 분야 | 상태 |
| --- | --- |
| 목적·범위 | 명확 |
| 사용자 흐름 | 명확 |
| 데이터 | 명확 |
| 외부 연동·API | 명확 |
| 기술 스택 | 명확 |
| 구조 | 가정 |
| 상태 관리 | 명확 |
| 에러·예외 | 명확 |
| 성능·보안 | 명확 |
| 테스트 | 가정 |
| 배포·일정 | 명확 |

### 기록

#### 1차 (2026-10-27)

- Q: 찜 탭 오류 문구를 어떻게 보여 줄까요? → A: A. 정해 둔 안내 문구로 바꾼다 (검색 #131과 같은 방식)
- Q: 이미 해제된 찜(404 4102)·이미 찜함(409 4101)을 어떻게 처리할까요? → A: A. 안내 문구를 보여 주고 목록을 다시 받는다
- Q: 어느 브랜치에서 시작할까요? → A: A. #131 병합 뒤 main에서 새 브랜치

<!-- #### 1차 (2026-10-27) / - Q: 질문 → A: 답 -->
