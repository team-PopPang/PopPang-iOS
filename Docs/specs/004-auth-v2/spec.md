# 회원가입 화면 V2 디자인 테크 스펙

- 상태: 완료
- 만든 날: 2026-11-02
- 체크리스트: [tasks.md](tasks.md) · 진행 기록: [log.md](log.md)

<!-- 상태 값: 인터뷰 중 → 설계 승인 대기 → 스펙 승인 대기 → 체크리스트 승인 대기 → 구현 중 → 완료 -->

## 기획 원문

- "이제 authfeaturev2만들거야 https://www.figma.com/design/asdKpjfFHPVtvKvDT3mMLs/...?node-id=2432-9525 부터 회원가입 화면 디자인 분석해줄래 4장" (2026-11-02)
- 피그마 "팝업스토어" 파일의 회원가입 4장: 2467-10836(닉네임), 2467-10856(카테고리), 2467-10890(키워드), 2467-10931(완료)
- "이해안가 피그마대로하면되는데 필요한 선택만다 시정리" (2026-11-02)
- "1. 그냥 아예 없앨거야 2. 5개로 할게 3. 이건 인기 키워드 api가 만들어졌어 … 4. 가입하고 완료 화면" (2026-11-02)
- 백엔드 공지 (2026-11-02, 붙여넣은 원문):

  ```text
  신규 API 2개 운영 배포 완료했습니다.

  공통
  - Base URL: https://api.poppang.co.kr
  - Header: Authorization: Bearer {token}
  - Access Token 또는 최신 Signup Token 사용
  - Query / Body 없음

  1. 랜덤 닉네임 추천
  GET /api/v2/user/nickname/recommendation

  응답 예시:
  {"success":true,"code":0,"message":"요청 성공!","data":{"nickname":"설레는수달"}}

  - 수식어+동물 조합, DB 중복 확인 후 반환
  - 추천은 예약이 아니므로 가입 시 중복 재확인
  - 추천 실패: HTTP 503 / code 4208

  2. 인기 알림 키워드
  GET /api/v2/alert-keyword/popular

  응답 예시:
  {"success":true,"code":0,"message":"요청 성공!","data":[{"alertKeyword":"소금빵"},{"alertKeyword":"산리오"}]}

  - 전체 사용자 등록 인원순으로 최대 6개 반환
  - 공백 제거·영문 소문자 통일, 동일 사용자 중복 제외
  - 동률이면 키워드 오름차순, 결과 없으면 data: []
  ```

- "5 추천대로. 6. 추천디자인은 이거참고 …node-id=2432-9525" (2026-11-02)
- "A 1번, B 추천대로, C 지금 규칙 유지" (2026-11-02)

## 1. 목표와 범위

<!-- 승인 뒤에는 사용자만 바꾼다. -->

### 왜 하는지

회원가입 화면을 피그마 새 디자인으로 바꾸고, 새로 나온 닉네임 추천·인기 키워드 API를 붙인다.

### 하는 것

- 새 모듈 `AuthFeatureV2`를 만들고 앱이 V2를 쓰게 바꾼다.
- 가입 3단계(닉네임, 카테고리, 키워드)를 새 디자인으로 바꾸고, 가입 완료 화면을 새로 만든다.
- 닉네임 추천 API와 인기 키워드 API를 Data·Domain에 추가하고 가입 화면에서 쓴다.

### 하지 않는 것

- 로그인 화면 디자인은 바꾸지 않는다 (모서리 15는 #137에서 이미 반영).
- 지역 선택은 만들지 않는다. 디자인의 "지역" 문구도 쓰지 않는다.
- 닉네임 규칙(공백 금지, 3자 이상)은 바꾸지 않는다. "2~10자 · 한글, 영문, 숫자" 안내 문구도 넣지 않는다.
- 키워드 최대 개수는 5개 그대로다.
- 가입 요청(`SignupRequest`) 형식과 가입 이후 흐름(메인 화면 이동, 푸시 토큰 동기화)은 바꾸지 않는다.

### 성공 기준

- 시뮬레이터에서 가입 4장이 피그마 화면과 같아 보인다.
- 닉네임 화면에 들어오면 추천 닉네임이 채워져 있고, "다른 닉네임 추천받기"로 바꿀 수 있다.
- 키워드 화면에 인기 키워드가 보이고, 누르면 내 키워드에 추가된다.
- 3단계 "다음"에서 가입이 끝나고 완료 화면이 나온다. "알림 켜고 시작하기"를 누르면 알림 권한을 묻고 메인 화면으로 간다.

### 제약

- 서버 API는 공지된 두 개 외에 새로 요구하지 않는다.

## 2. 요구사항

- **R1** 가입은 닉네임(1/3) → 카테고리(2/3) → 키워드(3/3) → 완료 순서다. 1~3단계 위에는 뒤로 `‹`, 진행 막대, `n/3`가 있다.
- **R2** 닉네임 화면은 `2467-10836` 디자인(입력칸 + 확인 버튼 + 확인 결과 문구)에 `2432-9525`의 "다른 닉네임 추천받기" 버튼만 더한다. (4차 답 A)
- **R3** 닉네임 화면에 들어오면 추천 닉네임을 입력칸에 채우고 "사용할 수 있는 닉네임이에요"로 표시한다. "다른 닉네임 추천받기"를 누르면 새 추천으로 바꾼다. (4차 답 B)
- **R4** 닉네임 규칙은 지금 그대로다: 공백 금지, 3자 이상, 확인 버튼으로 중복 확인. (4차 답 C)
- **R5** 카테고리 화면은 서버 카테고리 목록을 칩으로 보여 주고, 여러 개 고를 수 있다. 버튼 위 요약은 "관심사 N개 선택됨"이다 (지역 없음, 2차 답 1).
- **R6** 키워드 화면에서 키워드를 직접 추가·삭제한다. 최대 5개이고 개수를 `N / 5`로 보여 준다. (2차 답 2)
- **R7** 키워드 화면에 인기 키워드(`GET /api/v2/alert-keyword/popular`, 최대 6개)를 "많이 등록한 키워드" 제목과 칩으로 보여 주고, 누르면 내 키워드에 추가한다. (2차 답 3, 3차 답 5)
- **R8** 키워드 화면 "다음"을 누르면 가입 요청을 보내고, 성공하면 완료 화면을 보여 준다. 건너뛰기도 같다. (2차 답 4)
- **R9** 완료 화면은 체크 아이콘, "준비 끝!\n{닉네임}님, 환영해요"(닉네임만 주황), 안내 카드 3항목, "알림 켜고 시작하기" 버튼이다. 카드 1번 설명은 고른 카테고리와 키워드를 " · "로 잇는다.
- **R10** "알림 켜고 시작하기"를 누르면 알림 권한을 요청하고, 결과와 관계없이 메인 화면으로 간다. 키워드를 추가할 때는 더 이상 알림 권한을 묻지 않는다. (2차 답 4)

## 3. 현재 코드

- 가입 흐름은 `AuthFeature` 모듈의 `RegisterFlowFeature`(259줄)·`RegisterFlowFeatureView`(461줄)다. 로그인 화면은 같은 모듈의 `AuthFeature`·`AuthFeatureView`다.
- `AppFeature`가 `registerFlow: RegisterFlowFeature.State?`를 `ifLet`으로 붙인다. `.delegate(.completed(user))` → `registerCompleted`(메인 이동, 푸시 토큰 동기화), `.delegate(.loginRequired)` → 로그인 화면으로 돌아감 (`8. AppFeature.swift:164`, `:238`, `:494`).
- 앱 의존: `2. AppBootstrap.swift`와 `7. AppRootFlowView.swift`가 `import AuthFeature`. `AuthFeatureClient.live(authUsecase:)`를 AppBootstrap에서 주입한다.
- `AuthFeatureClient`: `login`, `signup`, `checkNickname`, `getRecommendList` (`AuthFeatureClient.swift`).
- 가입 API는 모두 V2이고 가입 토큰(`.signup` 권한)으로 부른다: `POST /auth/{provider}/signup`, `GET /user/nickname/duplicated`, `GET /recommend` (`AuthAPI.swift`).
- 가입 토큰 만료(401/5002·5014·5006)는 `AuthError.signupSessionExpired`로 바뀌고, 화면은 `loginRequired`로 로그인부터 다시 하게 한다 (`AuthRepositoryImpl.swift:156`).
- 지금 동작:
  - 닉네임 단계에는 뒤로가기·건너뛰기가 없다. 카테고리·키워드 단계에는 둘 다 있다.
  - 카테고리는 1개 이상 골라야 다음으로 간다. 건너뛰기로 넘길 수 있다.
  - 키워드는 최대 5개. 키워드를 추가할 때 알림 권한을 묻고, 거부했으면 설정 이동 알림을 띄운다 (`RegisterFlowFeatureView.swift:427`).
  - 키워드 "다음"·건너뛰기에서 가입하고 바로 `completed`로 메인에 간다. `isAlerted`는 키워드가 있으면 `true`.
- `AuthFeatureDemo` 타깃은 주석 처리돼 있다 (`AuthFeature/Project.swift:37`).
- 선례: `OnboardingFeatureV2`, `HomeFeatureV2`는 새 모듈을 만들고 같은 타입 이름을 쓰며, 기존 모듈은 남겨 두었다.
- DSKit 색: `mainOrange #FF7A00`, `mainBlack #333333`, `subWhite3 #F2F2F2`, `mainGray6 #999999`, `onboardingGray #8B8B8B`, `onboardingBody #555555`가 있다 (`UIConstants.swift`). 글꼴은 `.scdream(.light/.regular/.medium/.extraBold)`.

피그마 값 (Talk to Figma `get_nodes_info`, 2026-11-02):

| 요소 | 값 |
| --- | --- |
| 화면 | 393×852, 흰 배경, 좌우 여백 20 |
| 뒤로 | `‹` Light 30 `#1A1A1A` (구현은 SF Symbol `chevron.left`) |
| 진행 막대 | 270×4, 모서리 2, 바탕 `#EDEDED`, 채움 `#FF7A00` |
| 단계 표시 | `1/3` Medium 14 `#8B8B8B`, 오른쪽 |
| 제목 | ExtraBold 24, 줄 높이 35.28, `#000000` |
| 아래 버튼 | 347×52, 모서리 10, `#FF7A00`, Medium 15 흰색 |
| 닉네임 입력칸 | 273×48, 모서리 12, 테두리 `#FF7A00`, Medium 17 `#1A1A1A`, 안쪽 여백 16 |
| 확인 버튼 | 62×45, 모서리 5, `#FF7A00`, Medium 12 흰색, 간격 10 |
| 확인 결과 | ExtraBold 13 `#1A8C3D`, "✓  사용할 수 있는 닉네임이에요", 입력칸 아래 13 |
| 추천받기 버튼 (2432-9525, 그림이라 눈대중) | 회색 캡슐, `arrow.clockwise` + "다른 닉네임 추천받기" |
| 섹션 라벨 | ExtraBold 14 `#333333` |
| 칩 | 높이 39, 모서리 19, 좌우 15, 간격 8 / 기본: 흰 바탕, 테두리 `#E0E0E0`, Light 14 `#333333` / 선택: `#FFF3E8`, 테두리 `#FF7A00`, ExtraBold 14 `#FF7A00`, "✓ " |
| 선택 요약 | Light 13 `#8C8C8C`, 가운데, 버튼 위 20 |
| 키워드 부제목 | Regular 14 `#555555` |
| 건너뛰기 | Medium 14 `#8C8C8C`, 키워드 제목 줄 오른쪽 |
| 키워드 입력칸 | 281×50, 모서리 12, `#F2F2F2`, 안내 Light 15 `#999999` "예: 두쫀쿠, 짱구, 레고" + 돋보기 |
| 추가 버튼 | 64×50, 모서리 12, `#1A1A1A`, ExtraBold 15 흰색, 간격 8 |
| 내 키워드 칩 | `#FFF3E8`, 테두리 없음, ExtraBold 14 `#FF7A00`, "키워드  ×" |
| 인기 키워드 칩 | 기본 칩, "+ 키워드" |
| 완료 아이콘 | 84 원 `#FFF3E8` 안에 58 원 `#FF7A00`, 흰 체크 |
| 완료 제목 | ExtraBold 26 `#121212`, 가운데, 닉네임만 `#FF7A00` |
| 안내 카드 | 338×225, 모서리 15, 흰 바탕, 그림자, 안쪽 여백 26, 항목 간격 22 |
| 카드 항목 | 체크 원 26 `#FFF3E8` + 주황 체크 14 / 제목 Medium 16 `#121212` / 설명 Light 13 `#8C8C8C` |

## 4. 설계

### 기술 스택

| 이름 | 버전 | 새로 들이는지 | 결정 |
| --- | --- | --- | --- |
| TCA, SwiftUI, Tuist, Moya | 레포 기준 | 아니요 | — |

### 구조

```text
App ──▶ AuthFeatureV2 (새 모듈, D-1)
          ├─ AuthFeature / AuthFeatureView        (로그인, 기존 코드 그대로 옮김)
          ├─ RegisterFlowFeature                  (단계 .nickname/.category/.keyword/.complete)
          ├─ RegisterFlowFeatureView + 단계별 View (새 디자인)
          ├─ AuthFeatureClient                    (+ recommendNickname, getPopularKeywords)
          └─ Resources/Localizable.xcstrings      (새 문구 ko·en·ja)
        ──▶ Domain: AuthRepositoryProtocol·AuthUsecase에 메서드 2개 추가 (D-3)
        ──▶ Data:   AuthAPI에 case 2개 추가, AuthRepositoryImpl 구현, 응답 DTO 2개
        ──▶ DSKit:  새 색 추가 (D-4)
AuthFeature (기존 모듈) — 그대로 남김 (D-2)
```

- 타입 이름은 그대로 쓰고 앱은 `import AuthFeatureV2`만 바꾼다 (`OnboardingFeatureV2`와 같은 방식). `AppFeature`의 연결 코드는 바꾸지 않는다.
- 완료 화면은 가입 흐름 안의 마지막 단계로 둔다. 가입 성공 시 `User`를 state에 들고 있다가 "알림 켜고 시작하기"에서 `.delegate(.completed(user))`를 보낸다 (D-5).

### 데이터 모델

- `RegisterRoute`: `.nickname`, `.category`, `.keyword`, `.complete`. 진행 막대·`n/3`은 앞의 3개만 센다.
- `RegisterFlowFeature.State`에 추가: `popularKeywords: [String]`, `signedUpUser: User?`.
- Domain: 인기 키워드는 `[String]`, 추천 닉네임은 `String`으로 돌려준다. 새 엔티티는 만들지 않는다.

### API

| 메서드 | 경로 | 권한 | 응답 | 실패 |
| --- | --- | --- | --- | --- |
| `recommendSignupNickname()` | `GET /api/v2/user/nickname/recommendation` | 가입 토큰 | `APIResponse<{ nickname }>` | 503/4208 → `AuthError.failed` |
| `fetchPopularKeywords()` | `GET /api/v2/alert-keyword/popular` | 가입 토큰 | `APIResponse<[{ alertKeyword }]>` | 빈 배열 가능 |

- 가입 토큰 만료는 기존 가입 API와 같이 `signupSessionExpired`로 바꾼다.

### 에러·예외 처리

- 닉네임 추천 실패: 입력칸을 비워 두고 아무것도 띄우지 않는다. 사용자가 직접 입력한다.
- 인기 키워드 실패·빈 배열: 인기 키워드 영역을 숨긴다.
- 가입 토큰 만료: 지금처럼 `loginRequired`로 로그인 화면에 돌아간다.
- 인기 키워드 칩을 눌렀는데 이미 5개이거나 같은 키워드가 있으면 지금 직접 추가할 때와 같이 처리한다.
- 가입 요청 중에는 "다음"·건너뛰기를 막는다 (지금과 같음).

### 테스트 방법

- `AuthFeatureV2Tests` (TestStore):
  - 진입 시 추천 닉네임이 채워지고 `validationState == .success`, 추천받기로 바뀜, 추천 실패 시 빈 칸
  - 인기 키워드 로드, 칩 탭 → 키워드 추가, 5개 제한
  - 키워드 "다음" → 가입 성공 → `.complete` 단계, 아직 `completed`를 보내지 않음
  - 완료 버튼 → `.delegate(.completed(user))`
  - 가입 토큰 만료 → `loginRequired`
  - 기존 `AuthFeatureTests`의 로그인·가입 테스트를 옮겨 그대로 통과
- Data: `AuthRepositoryTests`에 두 API의 경로·권한·디코딩 테스트
- Demo 타깃 `AuthFeatureV2Demo`: 가짜 client로 가입 흐름만 띄워 피그마와 비교
- 시뮬레이터: 실제 가입으로 4장 흐름, 알림 권한 팝업, 메인 이동 확인. iPhone SE에서 잘리지 않는지 확인

## 5. 결정 기록

### D-1 새 모듈로 만들기
- 결정: `AuthFeatureV2` 모듈을 새로 만들고 앱이 V2에 의존한다. 로그인 화면도 같이 옮긴다
- 이유: 사용자 요청("authfeaturev2 만들거야"). `OnboardingFeatureV2`와 같은 방식. 로그인과 가입이 한 모듈에 있어서 같이 옮겨야 앱이 한 모듈만 쓴다
- 검토한 대안: 기존 `AuthFeature` 안에서 가입 화면만 바꾸기 (변경이 적지만 요청과 다름)
- 영향: R1~R10
- 정한 사람: 모듈 생성은 사용자 (2026-11-02), 로그인 함께 옮기기는 AI 제안·사용자 확인 (2026-11-02 설계 승인)

### D-2 기존 `AuthFeature` 모듈
- 결정: 지우지 않고 남긴다. 앱 의존성에서만 뺀다
- 이유: `OnboardingFeature`, `HomeFeature`를 남긴 선례. 되돌리기 쉽다
- 검토한 대안: 이번에 지운다
- 영향: R1
- 정한 사람: AI 제안, 사용자 확인 (2026-11-02 설계 승인)

### D-3 새 API를 넣을 자리
- 결정: 기존 `AuthAPI`·`AuthRepositoryProtocol`·`AuthUsecase`에 메서드를 추가한다 (`recommendSignupNickname`, `fetchPopularKeywords`)
- 이유: 둘 다 가입 화면에서 가입 토큰으로 부르는 API라 기존 가입 API(`checkSignupNickname`, `fetchSignupRecommendList`)와 같은 자리다
- 검토한 대안: 인기 키워드를 키워드(Alert) 쪽 저장소에 두기 (다른 화면에서도 쓸 때 맞지만, 지금 그 저장소는 Access Token 전용)
- 영향: R3, R7
- 정한 사람: AI 제안, 사용자 확인 (2026-11-02 설계 승인)

### D-4 새 색
- 결정: 피그마 값 그대로 DSKit `UIConstants.swift`에 추가한다. `#8C8C8C`는 `onboardingGray`(#8B8B8B), `#555555`는 `onboardingBody`를 쓴다. 새로 넣는 색: `registerText #1A1A1A`, `registerTitle #121212`, `registerTrack #EDEDED`, `registerChipBorder #E0E0E0`, `registerChipSelected #FFF3E8`, `registerValid #1A8C3D`
- 이유: 온보딩 V2와 같은 방식(D-5). 거의 같은 회색은 합친다
- 검토한 대안: 기존 토큰 중 비슷한 색으로 맞추기 (`mainGreen #006813`, `mainGray5 #EEEEEE` 등, 색이 눈에 띄게 다름)
- 영향: R1~R9
- 정한 사람: AI 제안, 사용자 확인 (2026-11-02 설계 승인)

### D-5 완료 화면 위치
- 결정: 가입 흐름(`RegisterFlowFeature`)의 마지막 단계로 둔다. 가입 성공 후 완료 버튼을 누를 때 `completed`를 보낸다
- 이유: `AppFeature`를 바꾸지 않아도 된다. 닉네임·카테고리·키워드를 이미 state에 들고 있다
- 검토한 대안: `AppFeature`가 완료 화면을 따로 띄우기 (앱 루트 흐름 변경이 커짐)
- 영향: R8, R9, R10
- 정한 사람: AI 제안, 사용자 확인 (2026-11-02 설계 승인)

## 6. 가정과 보류

### 가정

- **A-1** 닉네임 단계의 뒤로 `‹`는 디자인에 있지만 지금처럼 숨긴다 (돌아갈 화면이 없음). AI 제안
- **A-2** 카테고리 단계에는 건너뛰기를 두지 않는다 (디자인에 없음). 1개 이상 골라야 다음으로 간다. AI 제안
- **A-3** 오류 문구(중복, 공백, 너무 짧음, 확인 실패)는 지금 문구를 쓰고, 모양은 확인 결과와 같은 ExtraBold 13, 색은 `mainRed`. AI 제안
- **A-4** 아래 버튼이 비활성일 때는 지금처럼 `mainGray2` 바탕. AI 제안
- **A-5** 알림 권한을 이미 거부한 사용자는 완료 버튼을 누르면 설정 이동 알림 없이 바로 메인으로 간다. AI 제안
- **A-6** 키워드 5개 초과 알림은 지금 알림을 그대로 쓴다. AI 제안
- **A-7** 안내 카드 그림자는 값을 읽지 못해서 이미지와 비슷하게 맞춘다 (`black 8%, 반경 16, y 4` 정도). AI 제안
- **A-8** 추천받기 버튼 크기·색은 그림(2432-9525) 눈대중이다: 높이 36, `#F2F2F2` 캡슐, SemiBold 13 `#333333`. AI 제안
- **A-9** 화면 전환은 지금처럼 옆으로 미는 애니메이션이다.
- **A-10** 배포는 PR 하나로 main에 병합한다. 마감은 없다.

### 보류

- 없음

## 7. 위험

- 닉네임 추천 값이 가입 사이에 다른 사람에게 쓰일 수 있다 → 가입 요청의 중복 닉네임(409/4204) 처리가 이미 있어 닉네임 단계로 돌아간다.
- 로그인 코드를 새 모듈로 복사하면 두 모듈에 같은 코드가 생긴다 → 앱은 V2만 쓰고, 기존 모듈은 나중에 지운다.
- `AuthRepositoryProtocol`(public protocol)에 메서드를 추가한다 → 이 프로토콜을 따르는 테스트용 가짜 객체도 함께 고친다.

## 8. 질문과 답

### 분야별 상태

| 분야 | 상태 |
| --- | --- |
| 목적·범위 | 명확 |
| 사용자 흐름 | 가정 |
| 데이터 | 명확 |
| 외부 연동·API | 명확 |
| 기술 스택 | 명확 |
| 구조 | 가정 |
| 상태 관리 | 명확 |
| 에러·예외 | 가정 |
| 성능·보안 | 명확 |
| 테스트 | 명확 |
| 배포·일정 | 가정 |

### 기록

#### 1차 (2026-11-02)
- Q: 피그마대로 하면 되고, 정해야 할 선택만 다시 정리 → A: 지역·키워드 개수·추천 키워드·가입 시점 4개로 정리

#### 2차 (2026-11-02)
- Q: 1. 지역 처리 2. 키워드 최대 개수 3. 추천 키워드 데이터 4. 가입 시점 → A: 1. 지역은 아예 없앤다 2. 5개 3. 인기 키워드 API가 생겼다(공지 원문은 기획 원문에) 4. 3단계에서 가입하고 완료 화면

#### 3차 (2026-11-02)
- Q: 5. 인기 키워드 제목 (전체 기준이라 "디저트 · 캐릭터를 고른 분들이…"가 맞지 않음) 6. 닉네임 추천 API 사용 방법 → A: 5. 추천대로 "많이 등록한 키워드" 6. 추천 디자인은 2432-9525 참고

#### 4차 (2026-11-02)
- Q: A. 닉네임 화면 모양 B. 추천 닉네임 동작 C. 닉네임 규칙 → A: A 1번(10836에 추천받기 버튼만 추가), B 추천대로(진입 시 채우고 바로 사용 가능 표시), C 지금 규칙 유지
