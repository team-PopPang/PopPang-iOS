# 온보딩 화면 V2 디자인 테크 스펙

- 상태: 완료
- 만든 날: 2026-11-01
- 체크리스트: [tasks.md](tasks.md) · 진행 기록: [log.md](log.md)

<!-- 상태 값: 인터뷰 중 → 설계 승인 대기 → 스펙 승인 대기 → 체크리스트 승인 대기 → 구현 중 → 완료 -->

## 기획 원문

- "onboardingfeaturev2만들건데 figma에 온보딩 새로운버전UI만들었어" (2026-11-01)
- "팝팡 온보딩 디자인 개선부분만 분석해봐" — 피그마 "팝업스토어" 파일, 섹션 "팝팡 리뉴얼 최종"(2467-10300)의 "팝팡 온보딩 탭 디자인 개선" 3장 (2467-10688, 2467-10769, 2467-10794)
- "온보딩 UI만 바뀐 작업이잖아. … 사진같은건 피그마꺼다운받고 버튼이나 글자는 직접 swiftui로하는게 좋을거같아, 그리고 마지막 화면 다음은 일단 현재 로그인 화면디자인 그대로." (2026-11-01)
- "1 시작하기 2 네 3 네 4 v2로 만들어" (2026-11-01)

## 1. 목표와 범위

<!-- 승인 뒤에는 사용자만 바꾼다. -->

### 왜 하는지

온보딩 3장을 피그마 새 디자인으로 바꾼다.

### 하는 것

- 새 모듈 `OnboardingFeatureV2`를 만들고 앱이 V2를 쓰게 바꾼다.
- 화면 배치, 문구, 그림, 아이콘, 점, 버튼을 새 디자인대로 만든다.

### 하지 않는 것

- 온보딩 흐름(화면 3장, 다음, 건너뛰기, 끝나면 로그인 화면)은 바꾸지 않는다.
- 로그인 화면과 피그마의 "로그인 탭 디자인 개선"(닉네임·카테고리·키워드·완료)은 하지 않는다.
- 서버·알림 기능은 건드리지 않는다.
- `MainOrangeButton`은 바꾸지 않는다.

### 성공 기준

- 시뮬레이터에서 온보딩 3장이 피그마 화면과 같아 보인다.
- 다음·건너뛰기·옆으로 넘기기·마지막 "시작하기"가 지금처럼 동작하고, 끝나면 지금 로그인 화면이 나온다.

### 제약

- 그림 이미지 안의 글자는 번역되지 않는다 (한국어 그대로).

## 2. 요구사항

- **R1** 화면 3장(키워드 알림, 지도, 캘린더 찜)을 새 배치로 보여 준다: 위에 그림 카드, 아래에 아이콘·제목·설명(왼쪽 정렬), 점, 버튼.
- **R2** 위쪽 그림 카드는 피그마에서 받은 PNG로 보여 준다.
- **R3** 아이콘(종, 지도 핀, 달력)과 버튼 화살표는 피그마에서 받은 SVG로 보여 준다.
- **R4** 제목·설명·건너뛰기·점·버튼은 SwiftUI로 그린다. 문구는 새 디자인 문구이고 ko·en·ja를 넣는다. 단, 3번 화면 설명은 지금 없는 종료 알림 대신 "캘린더에 한눈에 정리되고, 날짜별로 바로 확인할 수 있어요"로 쓴다. (2차 답)
- **R5** 버튼은 "다음 →"이고, 마지막 화면만 "시작하기"다. (사용자 답 1)
- **R6** 마지막 화면 버튼과 건너뛰기를 누르면 지금처럼 로그인 화면으로 간다.
- **R7** 앱에 없는 색 `#8B8B8B`, `#FEF2E7`, `#555555`, `#D9D9D9`를 DSKit에 추가한다. (사용자 답 2)

## 3. 현재 코드

- 앱은 로그인한 사용자가 없으면 온보딩을 띄운다 (`AppLaunchStateResolver.swift:10`).
- `AppFeature`가 `OnboardingFeature`를 Scope로 붙이고, `.delegate(.authRequested)`를 받으면 온보딩 완료를 저장하고 로그인 화면을 push한다 (`8. AppFeature.swift:169`, `:218`).
- `OnboardingFeature`(48줄): `currentStep`(`.keyword`, `.map`, `.favorite`), `nextTapped`(마지막이면 `authRequested`), `skipTapped`, `stepChanged` (`OnboardingFeature.swift`).
- `OnboardingFeatureView`: 페이지형 `TabView`, 로고 `Logo1~3`, 제목 18 ExtraBold 가운데, 설명 15, 그림 `Onboarding1~3`(화면 높이 45%), 점(검정 12×6 / 회색 6×6), `MainOrangeButton`, 건너뛰기 12pt 검정, 배경 `subWhite3` (`OnboardingFeatureView.swift`).
- 이미지는 DSKit `Assets.xcassets/Onboarding`, 문구는 `OnboardingFeature/Resources/Localizable.xcstrings`.
- 앱 타깃만 `OnboardingFeature`에 의존한다 (`Projects/App/Project.swift:138`).
- 같은 V2 방식의 선례: `HomeFeatureV2`는 새 모듈로 만들고 `MainTabFeature`가 V2에 의존한다. 기존 `HomeFeature`는 남아 있다.
- `MainOrangeButton`: 모서리 5, 높이 56, Bold 14, 화살표 없음 (`MainOrangeButton.swift`).
- 글꼴은 S-Core Dream 1~9가 DSKit에 있다. Noto Sans KR은 없다.

피그마 값 (get_design_context, 2026-11-01):

| 요소 | 값 |
| --- | --- |
| 화면 | 393×852, 배경 `#FFFFFF` |
| 건너뛰기 | S-Core Dream Medium 14, `#8B8B8B`, 오른쪽 여백 20, 높이 37 줄 |
| 그림 카드 | 353×379~383, 배경 `#FEF2E7`, 모서리 20, 화면 여백 20 |
| 아이콘 | 30×30 |
| 제목 | S-Core Dream ExtraBold 24, 줄 간격 1.47, `#000000`, 2줄 |
| 설명 | S-Core Dream Regular 14, 줄 간격 1.47, `#555555`, 2줄 |
| 아이콘·제목·설명 간격 | 9 |
| 점 | 현재 `#333333` 17×8, 나머지 `#D9D9D9` 8×8, 간격 10 |
| 버튼 | `#FF7A00`, 347×52(양옆 23), 모서리 10, Medium 15 흰색, 화살표 24, 간격 10 |

## 4. 설계

### 기술 스택

| 이름 | 버전 | 새로 들이는지 | 결정 |
| --- | --- | --- | --- |
| TCA, SwiftUI, Tuist | 레포 기준 | 아니요 | — |

### 구조

```text
App ──▶ OnboardingFeatureV2 (새 모듈, D-1)
          ├─ OnboardingFeature (Reducer, 기존 코드를 옮김)
          ├─ OnboardingFeatureView (새 디자인)
          ├─ OnboardingNextButton (화살표 버튼, 모듈 안 전용)
          └─ Resources/Localizable.xcstrings (새 문구)
        ──▶ DSKit (색 4개 추가, Assets.xcassets/OnboardingV2: 카드 PNG 3, 아이콘 SVG 4)
OnboardingFeature (기존 모듈) — 그대로 남김 (D-2)
```

- 타입 이름은 `OnboardingFeature`, `OnboardingFeatureView`, `OnboardingStep`을 그대로 쓴다. 앱은 `import OnboardingFeatureV2`만 바꾼다 (`HomeFeatureV2`와 같은 방식).

### 데이터 모델

`OnboardingStep`(`.keyword`, `.map`, `.favorite`)에 새 문구·아이콘·카드 이미지 이름을 둔다.

에셋 (DSKit `Assets.xcassets/OnboardingV2/`):

| 이름 | 형식 | 피그마 노드 |
| --- | --- | --- |
| `OnboardingV2Card1~3` | PNG @2x·@3x, 카드 전체(배경·모서리 포함) | 2467-10693, 2467-10774, 2467-10799 |
| `OnboardingV2IconBell`, `OnboardingV2IconMapPin`, `OnboardingV2IconCalendar` | SVG | 2467-10754 및 2·3번 화면의 같은 자리 |
| `OnboardingV2Arrow` | SVG | 2467-10766 |

문구 (제목·설명은 두 줄, `\n`으로 줄을 나눈다. en·ja는 AI 번역, 기존 표기 `popup`·`ポップアップ`를 따른다):

| 키 (ko) | en | ja |
| --- | --- | --- |
| 놓치기 싫은 팝업,\n키워드만 등록하세요 | Never miss a popup.\nJust add your keywords | 見逃したくないポップアップは、\nキーワードを登録するだけ |
| 브랜드, 캐릭터, 지역 키워드를 등록하면\n관련 팝업이 열리는 순간 알려드려요. | Add brand, character, or area keywords\nand we'll alert you the moment a related popup opens. | ブランド・キャラクター・地域のキーワードを登録すると、\n関連ポップアップのオープンをすぐにお知らせします。 |
| 지금 근처에서 열린 팝업,\n지도로 한눈에 | Popups open near you,\nall on one map | 近くで開催中のポップアップを、\n地図でひと目で |
| 지도 앱엔 안 나오는 팝업까지,\n거리와 마감 시간을 함께 보여드려요. | Even popups other map apps miss,\nwith distance and closing time. | 地図アプリにないポップアップまで、\n距離と終了時間と一緒にお見せします。 |
| 가고 싶은 팝업은\n캘린더에 찜해두세요 | Save the popups you want to visit\nto your calendar | 行きたいポップアップは\nカレンダーに保存しましょう |
| 캘린더에 한눈에 정리되고,\n날짜별로 바로 확인할 수 있어요 | See them all on your calendar,\nand check them by date | カレンダーにひと目で整理され、\n日付ごとにすぐ確認できます |
| 다음 / 시작하기 / 건너뛰기 | 기존 번역 그대로 (Next / Get Started / Skip) | 기존 번역 그대로 (次へ / 始める / スキップ) |

### API

없음.

### 에러·예외 처리

없음. 이미지를 못 찾으면 빈 카드가 보인다 (빌드 시 에셋 이름 확인).

### 테스트 방법

- 새 타깃 `OnboardingFeatureV2Tests`: TestStore로 다음 → 다음 단계, 마지막 다음 → `authRequested`, 건너뛰기 → `authRequested`, 넘기기 → `stepChanged`.
- Demo 타깃 `OnboardingFeatureV2Demo`: 로그인 없이 온보딩만 띄워 피그마 화면과 비교한다.
- 시뮬레이터에서 새로 설치한 앱(온보딩 보이는 상태)으로 흐름과 로그인 화면 이동을 확인한다. 화면 크기가 다른 기기(iPhone SE, Pro Max)에서도 잘리지 않는지 본다.

## 5. 결정 기록

### D-1 새 모듈로 만들기
- 결정: `OnboardingFeatureV2` 모듈을 새로 만들고 앱이 V2에 의존한다
- 이유: 사용자 요청. `HomeFeatureV2`와 같은 방식
- 검토한 대안: 기존 `OnboardingFeature` 화면만 바꾸기 (코드가 적어 더 간단)
- 영향: R1~R6
- 정한 사람: 사용자 (2026-11-01)

### D-2 기존 `OnboardingFeature` 모듈
- 결정: 이번에는 지우지 않고 남긴다. 앱 의존성에서만 뺀다
- 이유: `HomeFeature`도 남겨 둔 선례가 있고, 되돌리기 쉽다
- 검토한 대안: 이번에 지운다 (정리되지만 되돌릴 때 다시 만들어야 함)
- 영향: R6
- 정한 사람: AI 제안, 사용자 확인 (2026-11-01 설계 승인)

### D-3 그림·아이콘 만드는 방법
- 결정: 그림 카드는 카드 전체를 PNG(@2x, @3x)로, 아이콘·화살표는 SVG로 받는다. 글자·버튼·점은 SwiftUI
- 이유: 장식 그림이라 이미지가 가장 단순하다. 2·3번은 피그마에서도 사진이다
- 검토한 대안: 1번 카드(칩·알림 카드)를 SwiftUI로 조립 (번역 가능하지만 일이 많다)
- 영향: R2, R3, R4
- 정한 사람: 사용자 (2026-11-01, "사진같은건 피그마꺼다운받고 버튼이나 글자는 직접 swiftui")

### D-4 버튼
- 결정: `MainOrangeButton`을 바꾸지 않고 V2 모듈 안에 화살표 버튼을 만든다
- 이유: 다른 화면이 `MainOrangeButton`을 쓴다
- 검토한 대안: `MainOrangeButton`에 화살표·모서리 옵션 추가
- 영향: R5
- 정한 사람: 사용자 (2026-11-01, 답 3)

### D-5 새 색 이름
- 결정: DSKit `UIConstants.swift`에 피그마 값 그대로 추가한다. 이름은 `onboardingGray`(#8B8B8B), `onboardingCard`(#FEF2E7), `onboardingBody`(#555555), `onboardingDot`(#D9D9D9)
- 이유: 값은 사용자 답 2. 지금은 온보딩에서만 쓴다
- 검토한 대안: `mainGray10`처럼 기존 번호 규칙 이름 (다른 화면에서도 쓸 때 맞음)
- 영향: R7
- 정한 사람: 값은 사용자 (2026-11-01), 이름은 AI 제안·사용자 확인 (2026-11-01 설계 승인)

## 6. 가정과 보류

### 가정

- **A-1** 화면 높이가 852보다 작은 기기에서는 그림 카드 높이를 줄여 버튼이 잘리지 않게 한다 (AI 제안).
- **A-2** 피그마 시안의 점은 3장 모두 첫 번째가 켜져 있지만, 앱에서는 현재 화면 점을 켠다.
- **A-3** 화면 전환 애니메이션은 지금처럼 옆으로 넘기기와 점 애니메이션을 쓴다.
- **A-4** 마지막 화면 "시작하기" 버튼에는 화살표를 붙이지 않는다 (AI 제안, 설계 승인 때 보여 줌).
- **A-5** 배포는 PR 하나로 main에 병합한다. 마감은 없다.

### 보류

- 없음

## 7. 위험

- 피그마 임시 이미지 주소는 7일 뒤 만료된다 → 받은 즉시 에셋으로 넣는다.
- 작은 화면에서 글자가 잘릴 수 있다 → SE 시뮬레이터로 확인한다.

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
| 성능·보안 | 명확 |
| 테스트 | 명확 |
| 배포·일정 | 명확 |

### 기록

#### 1차 (2026-11-01)
- Q: 마지막 화면 버튼 글자 → A: 시작하기
- Q: 앱에 없는 색 4개를 DSKit에 추가? → A: 네
- Q: `MainOrangeButton`은 두고 온보딩 전용 버튼? → A: 네
- Q: 새 모듈 V2 vs 기존 화면만 변경 → A: V2로 만든다

#### 2차 (2026-11-01)
- Q: 3번 설명의 "종료 직전에 다시 알려드려요"는 지금 없는 기능이라 다른 문구? → A: "캘린더에 한눈에 정리되고, 날짜별로 바로 확인할 수 있어요" (1번안)
