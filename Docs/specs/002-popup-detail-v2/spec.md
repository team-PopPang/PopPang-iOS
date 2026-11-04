# 팝업 상세 화면 V2 전환 테크 스펙

- 상태: 완료
- 만든 날: 2026-10-30
- 체크리스트: [tasks.md](tasks.md) · 진행 기록: [log.md](log.md)

<!-- 상태 값: 인터뷰 중 → 설계 승인 대기 → 스펙 승인 대기 → 체크리스트 승인 대기 → 구현 중 → 완료 -->

## 기획 원문

- "팝업 목록에서도 팝업 데이터 그대로 popup쓸거야. 상세화면에서 팝업 호출하는거할거고" (2026-10-30)
- "상세는 /api/v2/user/popups/{popupUuid} 할거야" (2026-10-30)
- 마이그레이션 순서 3번: PopupDetailFeature를 V2 API로 전환한다 (`Docs/architecture/api-v2-migration.md`).
- "B방식으로하려는거야이유는 상세 내용이많아지기도 할거고 상세화면은 나중에 팝업 뿐만아니라 다른 데이터들도 들어올거라 팝업보다 더포괄적인객체가될수있어. 그래서 B로할거고 나중에 sdui할떄도 상세화면에서 호출방식인 B가 교체용이할거야" (2026-11-04)

## 1. 목표와 범위

<!-- 승인 뒤에는 사용자만 바꾼다. -->

### 왜 하는지

상세 화면이 V1 API와 `userUuid`로 호출한다. V2로 옮겨 Access Token의 사용자로 호출하고, 9번 정리 단계에서 V1 코드를 지울 수 있게 한다.

### 하는 것

- 상세 화면은 `popupUuid`만 받아 열리고, 화면 내용은 V2 단건 조회로 직접 불러온다 (B 방식, D-6).
- 상세 전용 데이터 모델 `PopupDetail`을 둔다. 목록용 `Popup`과 나눠 나중에 상세 전용 데이터를 더할 수 있게 한다 (D-7).
- 불러오는 동안 로딩, 실패하면 오류 화면을 보여 준다 (D-8).
- 조회 기록, 관련 팝업, 찜 등록·해제, 관리자 비활성화 호출을 V2로 바꾼다.
- MainTab이 상세 화면을 열 때 `popupUuid`만 넘기게 바꾼다.

### 하지 않는 것

- 각 탭(홈·지도·캘린더·찜·알림·검색)이 MainTab에 보내는 `popupSelected(Popup)`는 바꾸지 않는다. MainTab이 `popupUuid`만 꺼내 쓴다. 각 탭을 V2로 옮길 때 바꾼다 (D-9).
- 불러온 뒤의 상세 화면 UI 배치는 바꾸지 않는다.
- 조회 기록·관련 팝업·비활성화 실패 문구는 보여 주지 않는다 (2차 답). 상세 데이터를 받지 못한 경우만 오류 화면을 보여 준다 (D-8).
- 상세에서 바꾼 하트를 홈 외의 탭에 알리는 일은 하지 않는다 (지금도 홈에만 알린다).

### 성공 기준

- 상세 화면 코드에서 V1 팝업·찜 호출과 `userUuid`가 사라진다.
- 상세 화면이 `popupUuid`만으로 열리고, 화면 값은 단건 조회 응답으로 그린다.
- 시뮬레이터에서 진입(로딩 → 내용), 하트, 관련 팝업 이동, 오류 화면이 동작한다.

### 제약

- 내부 마이그레이션 명세와 API 계약 문서는 레포(공개)에 복사하지 않는다. 필요한 경로·코드만 적는다.
- API 계약 문서는 백엔드 작업 브랜치 기준이며 운영 일치는 미검증이다.

## 2. 요구사항

- **R1** 상세 화면은 `popupUuid`만 받아 열린다. 응답을 받기 전에는 로딩을 보여 준다. (2026-11-04 변경: D-6. 이전: 넘겨받은 `Popup`을 먼저 보여 준다)
- **R2** 상세 화면이 열리면 `GET /api/v2/user/popups/{popupUuid}`로 상세 데이터를 받아 화면을 그린다. (1차 답)
- **R3** 조회 기록을 `POST /api/v2/popup/{popupUuid}/view`로 남긴다.
- **R4** 관련 팝업을 V2로 받는다. 경로에 `userUuid`를 넣지 않는다.
- **R5** 하트는 #133의 V2 찜 등록·해제(`addFavorite(popupUuid:)`, `removeFavorite(popupUuid:)`)를 쓴다.
- **R6** 단건 조회가 실패하면 오류 화면을 보여 준다. 없는 팝업(404 4301)이면 "팝업을 찾을 수 없어요"와 뒤로 가기, 그 밖의 실패면 "팝업을 불러오지 못했어요"와 다시 시도. (2026-11-04 변경: D-8. 이전: 넘겨받은 팝업을 그대로 보여 주고 문구 없음)
- **R8** MainTab의 상세 진입(탭 공통, 검색, 관련 팝업)은 `popupUuid`만 넘긴다. (2026-11-04, D-6·D-9)
- **R7** 관리자 비활성화를 `PATCH /api/v2/admin/popup/{popupUuid}/deactivate`로 바꾼다. (2차 답)

## 3. 현재 코드

- 상세 화면은 단건 조회를 하지 않는다. `State.popup`은 목록에서 받은 값 그대로다 (`PopupDetailFeature.swift`).
- `onAppear`에서 조회수 증가와 관련 팝업을 동시에 부른다. 둘 중 하나라도 실패하면 `error.localizedDescription`을 `errorMessage`에 넣는다 (`PopupDetailFeature.swift` `loadPopupDetail`).
- `errorMessage`는 화면 어디에서도 보여 주지 않는다 (`PopupDetailFeatureView.swift`에 사용처 없음).
- `State`가 `userUuid`를 가지고 찜·관련 팝업·관리자 비활성화에 넘긴다.
- 하트는 먼저 값을 바꾸고 delegate `favoriteChanged`로 MainTab에 알린 뒤 요청한다 (`MainTabFeature.swift:420`).
- `PopupDetailClient`: `increaseViewCount`, `getPersonalRelatedPopupList(userUuid, popupUuid)`, `addFavorite/removeFavorite(userUuid, popupUuid)`, `deactivatePopup(adminUuid, popupUuid)`.
- V1 경로: 조회수 `/popup/{uuid}/view`, 관련 팝업 `/users/{userUuid}/popups/{uuid}/related` (`PopupAPI.swift`), 비활성화 `AdminAPI.deactivatePopup` (`AdminAPI.swift`).
- 관리자 비활성화 V2(`PATCH /api/v2/admin/popup/{popupUuid}/deactivate`)는 API 계약 문서에 있다. Data에는 아직 없다.
- 상세 화면 기능 테스트 타깃은 없다.
- 하트 요청이 실패하면 이전 값으로 되돌리고 delegate로 다시 알린다 (`toggleLike` effect).
- `increaseViewCount`, `getPersonalRelatedPopupList`, `deactivatePopup(adminUuid:popupUuid:)`는 상세 화면에서만 쓴다 (Features 검색 결과).
- `State.userUuid`는 관련 팝업을 눌렀을 때 MainTab의 `pushPopupDetail(userUuid, popup)`로도 넘어간다 (`PopupDetailFeatureView.swift:90`, `MainTabFeature.swift`).
- `AdminRepositoryImpl`은 provider를 주입받지 않아 테스트에서 가짜 응답을 넣을 수 없다.
- 상세 진입점은 8곳(홈, 캘린더, 찜, 지도, 오픈 예정, 알림, 검색, 관련 팝업)이고 모두 `MainTabFeature.appendPopupDetail` 또는 `SearchDestinationFeature.appendPopupDetail`을 거친다 (`MainTabFeature.swift`, 2026-11-04 확인).
- MainTab의 `PopupDetailDestinationFeature`가 상세를 감싸고 `pushPopupDetail(String, Popup)`·`favoriteChanged`·`close` delegate를 올린다. `pushPopupDetail`의 첫 값(`userUuid`)은 쓰지 않는다.
- `PopupDetailClient.live`는 `MainTabFeatureDependencies`에서 만든다.

## 4. 설계

### 기술 스택

| 이름 | 버전 | 새로 들이는지 | 결정 |
| --- | --- | --- | --- |
| 기존 스택 (TCA, Moya, Swift Testing) | 레포 기준 | 아니요 | — |

### 구조

```text
MainTab (appendPopupDetail) ── popupUuid ──▶ PopupDetailFeature
PopupDetailFeature (onAppear, 다시 시도)
 ├─ getPopupDetail ────▶ PopupUsecase ─▶ PopupRepositoryImpl ─▶ V2PopupAPI.detail  → PopupDetailDTO → PopupDetail
 ├─ increaseViewCount ─▶ PopupUsecase ─▶ PopupRepositoryImpl ─▶ V2PopupAPI.view
 └─ getRelatedPopupList ▶ PopupUsecase ─▶ PopupRepositoryImpl ─▶ V2PopupAPI.related → [Popup]
PopupDetailFeature (하트)  ─▶ addFavorite/removeFavorite(popupUuid:) ─▶ V2FavoriteAPI (#133)
PopupDetailFeature (비활성화) ─▶ AdminUsecase ─▶ AdminRepositoryImpl ─▶ V2AdminAPI.deactivatePopup
```

- `onAppear`의 세 요청은 서로 따로 보낸다. 관련 팝업·조회 기록이 실패해도 상세 내용은 보여 준다.
- 다시 시도는 상세 데이터만 다시 받는다.

### 상태 관리

- `State`: `popupUuid`(고정), `detailState`(`loading` · `loaded(PopupDetail)` · `failed(DetailLoadFailure)`), `relatedPopupList`, `isDeactivating`, `didDeactivate`, `errorMessage`(화면에 보이지 않음)
- `DetailLoadFailure`: `notFound`(404 4301), `failed`(그 밖)
- 하트·공유·관리자 비활성화는 `loaded`일 때만 동작한다.
- `userUuid`는 상세 State에서 지운다 (D-3 대체).
- MainTab `PopupDetailDestinationFeature.State(popupUuid:isAdmin:hidesSystemTabBar:)`, delegate `pushPopupDetail(popupUuid: String)`.

### 데이터 모델

- Domain에 `PopupDetail`을 새로 둔다. 지금은 `Popup`이 가진 값과 같다(이름, 이미지, 주소, 기간, 시간, 설명, 태그, 인스타 링크, 조회수, 찜 수, 하트 상태 등).
- Data에 `PopupDetailDTO`를 새로 둔다. 지금 단건 응답은 `PopupDTO`와 같은 키에 `isFavorited`가 있다. null 처리는 `PopupDTO`와 같다(#130).
- 관련 팝업은 목록이라 `Popup`을 그대로 쓴다.

### API

| 기능 | V2 | 응답 |
| --- | --- | --- |
| 단건 조회 | `GET /api/v2/user/popups/{popupUuid}` | 감싸지 않은 단건 (`PopupDetailDTO`) |
| 조회 기록 | `POST /api/v2/popup/{popupUuid}/view` | 빈 본문 |
| 관련 팝업 | `GET /api/v2/user/popups/{popupUuid}/related` | 감싸지 않은 `[PopupDTO]` |
| 관리자 비활성화 | `PATCH /api/v2/admin/popup/{popupUuid}/deactivate` | 200 빈 본문. query `uuid` 없음 |

Domain 함수 (V1 함수를 바꾼다. D-2):

- `getPopupDetail(popupUuid:) -> PopupDetail` (새로 추가)
- `increaseViewCount(popupUuid:)` (이름 그대로, 경로만 V2)
- `getPersonalRelatedPopupList(userUuid:popupUuid:)` → `getRelatedPopupList(popupUuid:)`
- `deactivatePopup(adminUuid:popupUuid:)` → `deactivatePopup(popupUuid:)`

### UI

- 로딩: 화면 가운데 로딩 표시. 위쪽 뒤로 가기 버튼은 그대로 둔다.
- 오류: 가운데 안내 문구와 버튼. `notFound`는 "팝업을 찾을 수 없어요" + 뒤로 가기, `failed`는 "팝업을 불러오지 못했어요" + 다시 시도. 문구는 ko·en·ja.
- 불러온 뒤 화면 배치는 지금과 같다.

### 에러·예외 처리

- Repository는 `popupRequest {}`로 감싼다. `AuthSessionError`와 취소는 그대로 던지고, 나머지는 로그를 남기고 `PopupError`로 던진다. 단건 조회의 404 4301은 `PopupError.notFound`로 구분한다 (새 case).
- 단건 조회 실패: 오류 화면 (R6).
- 조회 기록·관련 팝업·비활성화 실패: 지금처럼 `errorMessage`에 넣는다. 화면에는 보이지 않는다.
- 하트 실패: 지금처럼 되돌린다.
- 로그인이 끊기면(`AuthSessionError`) 지금처럼 앱의 로그인 흐름이 처리한다.

### 테스트 방법

- Data (`PopupRepositoryTests`, 새 `AdminRepositoryTests`): 가짜 응답으로 경로·메서드·헤더·디코딩·실패 변환을 확인한다. 서버는 부르지 않는다. (3차 답)
- 새 타깃 `PopupDetailFeatureTests`: 가짜 client로 TestStore 상태 변화를 확인한다. 로딩 → 내용, 404 → 찾을 수 없음, 그 밖의 실패 → 다시 시도, 관련 팝업 실패에도 내용 표시, 하트, 비활성화 (3차 답)
- MainTab: 상세 진입이 `popupUuid`만 넘기는지 기존 `MainTabFeatureTests`에 확인을 더한다.
- 로컬에서 `xcodebuild test`로 실행한다. CI는 Data만 돌린다.
- 시뮬레이터에서 상세 진입(로딩 → 내용), 하트, 관련 팝업, 비활성화, 오류 화면(Demo 가짜 실패)을 직접 확인한다.

## 5. 결정 기록

### D-1 상세 단건 조회 API
- 결정: `GET /api/v2/user/popups/{popupUuid}`
- 이유: 하트 상태(`isFavorited`)가 응답에 있다
- 검토한 대안: `GET /api/v2/popup/{popupUuid}` (`isFavorited` 없음)
- 영향: R2
- 정한 사람: 사용자 (2026-10-30)

### D-2 V1 함수 처리
- 결정: 상세 화면 전용 V1 함수를 V2 함수로 바꾼다
- 이유: 다른 화면이 쓰지 않아 남겨 둘 이유가 없다. 9번 정리 단계 일이 줄어든다
- 검토한 대안: V2 함수를 새로 추가하고 V1은 9번에서 지운다 (찜 작업 방식, V1이 다른 화면에서도 쓰일 때 맞는 방식)
- 영향: R3, R4, R7
- 정한 사람: AI 제안, 사용자 확인 (2026-11-04 설계 승인)

### D-3 `State.userUuid` (대체됨: D-6)
- 결정: 이번에는 남긴다. API 호출에는 쓰지 않는다
- 이유: MainTab 화면 이동(`pushPopupDetail`)이 아직 쓴다. 지우면 MainTab까지 바뀐다
- 검토한 대안: 지금 지우고 MainTab 이동도 함께 고친다
- 영향: R4, R5, R7
- 정한 사람: AI 제안 (2026-10-30). B 방식으로 MainTab 진입을 함께 바꾸게 되어 D-6으로 대체 — 상세에서 지운다

### D-4 하트를 누른 뒤 단건 응답이 올 때 (대체됨: D-6)
- 결정: 하트 상태와 찜 수는 화면 값을 지키고, 나머지 값만 응답으로 바꾼다
- 이유: 응답이 누르기 전 상태일 수 있다. 덮어쓰면 하트가 되돌아간다
- 검토한 대안: 응답으로 모두 덮어쓴다
- 영향: R2, R5
- 정한 사람: AI 제안 (2026-10-30). D-6에서 하트는 불러온 뒤에만 누를 수 있어 필요 없어짐

### D-5 관리자 V2 API 위치
- 결정: 새 `V2AdminAPI` 파일을 만들고 `AdminRepositoryImpl`이 provider를 주입받게 한다
- 이유: `V2FavoriteAPI`처럼 영역별로 나눈 기존 방식과 같다. 주입해야 테스트할 수 있다
- 검토한 대안: `V2PopupAPI`에 case를 추가한다 (관리자 권한 API가 회원 팝업 API에 섞인다)
- 영향: R7
- 정한 사람: AI 제안, 사용자 확인 (2026-11-04 설계 승인)

### D-6 상세 화면은 `popupUuid`만 받아 직접 불러온다 (B 방식)
- 결정: MainTab은 `popupUuid`만 넘기고, 상세 화면이 단건 조회로 내용을 그린다. 상세에서 `userUuid`를 지운다 (D-3·D-4 대체)
- 이유: 상세 내용이 늘어나고, 상세는 팝업보다 넓은 객체가 될 수 있다. 나중에 SDUI로 바꿀 때 상세가 직접 부르는 방식이 교체하기 쉽다. 푸시·링크처럼 `popupUuid`만 있는 진입도 열 수 있다
- 검토한 대안: 넘겨받은 `Popup`을 먼저 보여 주고 단건 조회로 갱신 (진입이 빠르지만 상세가 목록 모델에 묶인다)
- 영향: R1, R2, R6, R8
- 정한 사람: 사용자 (2026-11-04)

### D-7 상세 전용 모델 `PopupDetail`
- 결정: Domain `PopupDetail`, Data `PopupDetailDTO`를 새로 둔다. 지금은 `Popup`과 같은 값으로 시작한다
- 이유: 상세 전용 데이터가 붙어도 목록용 `Popup`을 건드리지 않는다. SDUI로 바꿀 때 이 모델과 불러오는 함수만 교체한다
- 검토한 대안: 단건 응답도 `Popup`으로 받는다 (지금은 간단하지만 상세가 넓어지면 목록 모델이 커진다)
- 영향: R2
- 정한 사람: AI 제안, 사용자 확인 (2026-11-04)

### D-8 로딩·오류 화면
- 결정: 받기 전에는 가운데 로딩. 404 4301이면 "팝업을 찾을 수 없어요" + 뒤로 가기, 그 밖의 실패면 "팝업을 불러오지 못했어요" + 다시 시도 (2차 답 "오류 문구 하지 않음"을 상세 데이터 실패에 한해 바꿈)
- 이유: B 방식에서는 실패하면 보여 줄 데이터가 없다. 없어진 팝업은 다시 시도해도 같다
- 검토한 대안: 실패하면 바로 뒤로 닫기 (사용자가 이유를 모른다)
- 영향: R1, R6
- 정한 사람: AI 제안, 사용자 확인 (2026-11-04)

### D-9 탭의 팝업 선택 신호
- 결정: 각 탭이 보내는 `popupSelected(Popup)`는 이번에 바꾸지 않고, MainTab이 `popupUuid`만 꺼낸다
- 이유: 탭 화면 6곳을 이번 범위에 넣지 않는다. 각 탭을 V2로 옮길 때 uuid로 바꾼다
- 검토한 대안: 지금 모든 탭의 신호를 `popupUuid`로 바꾼다 (범위가 커진다)
- 영향: R8
- 정한 사람: AI 제안, 사용자 확인 (2026-11-04)

## 6. 가정과 보류

### 가정

- **A-1** API 계약 문서의 V2 경로가 운영 서버에 배포돼 있다 (백엔드 확인, 구현 전).
- **A-2** 단건 응답의 하트 상태가 목록과 달라도 목록 화면에는 알리지 않는다. 하트를 누를 때만 지금처럼 알린다 (AI 제안).
- **A-5** 단건 조회의 없는 팝업 응답은 404 4301이다 (API 계약 문서 기준, 운영 확인 필요).
- **A-3** 성능·보안은 기존 방식(토큰 헤더, 이미지 미리 받기)을 그대로 쓴다.
- **A-4** 배포는 다른 화면과 같이 한 PR로 main에 병합한다. 마감은 없다.

### 보류

- 각 탭의 `popupSelected(Popup)`를 `popupUuid`로 바꾸는 일 (D-9, 각 탭 V2 전환 때)
- 상세에서 바꾼 하트를 홈 외의 탭에 알리는 일
- 진입할 때 목록 값을 미리 보여 주는 방식 (느린 망에서 필요하면)

## 7. 위험

- 계약 문서와 운영 서버가 다를 수 있다 → 시뮬레이터에서 실제 응답을 확인한다.
- 진입할 때마다 네트워크를 기다리므로 느린 망에서 로딩이 길게 보일 수 있다 → 로딩 표시로 안내한다. 필요하면 나중에 목록 값을 미리 보여 주는 방식을 더할 수 있다.

## 8. 질문과 답

### 분야별 상태

| 분야 | 상태 |
| --- | --- |
| 목적·범위 | 명확 |
| 사용자 흐름 | 명확 |
| 데이터 | 명확 |
| 외부 연동·API | 명확 |
| 기술 스택 | 명확 |
| 구조 | 명확 |
| 상태 관리 | 명확 |
| 에러·예외 | 명확 |
| 성능·보안 | 가정 |
| 테스트 | 명확 |
| 배포·일정 | 가정 |

### 기록

#### 1차 (2026-10-30)
- Q: 상세 단건 조회 API는? → A: `/api/v2/user/popups/{popupUuid}`

#### 2차 (2026-10-30)
- Q: 단건 조회 실패·404 처리는? → A: 오류 문구는 일단 하지 않는다
- Q: 관리자 비활성화 V2도 함께? → A: 함께 한다
- Q: 테스트 방식은? → A: 다시 설명 요청 (3차에서 다시 묻는다)

#### 3차 (2026-10-30)
- Q: Data 테스트와 상세 화면 TestStore 테스트를 모두 만들까? → A: 둘 다 만든다

#### 4차 (2026-11-04)
- Q: 상세 진입 때 넘겨받은 팝업을 먼저 보여 줄까(A), `popupUuid`만 넘기고 불러올까(B)? → A: B. 상세 내용이 늘고, 팝업보다 넓은 객체가 될 수 있고, SDUI로 바꾸기 쉽다
- Q: 로딩·오류 화면, `PopupDetail` 모델, 탭 신호 유지, D-2·D-5 → A: 추천대로
