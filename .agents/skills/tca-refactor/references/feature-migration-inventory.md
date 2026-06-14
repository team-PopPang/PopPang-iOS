# Feature Migration Inventory

이 문서는 PopPang의 Compound -> TCA 전환 현황과 issue 기반 우선순위를 기록한다.

migration이 진행되면 이 문서를 함께 업데이트한다.

## 기준 시점

- 작성 기준: 2026-06-14
- 활성 코드 기준: 루트 `Projects/*`

## 현재 상태 요약

### TCA 예시가 이미 존재하는 feature

- `HomeFeature`
  - `HomeFeatureReducer`
  - `ComingPopupDetailReducer`
- `PopupDetailFeature`
  - `PopupDetailFeatureReducer`

### Compound 기반 feature

- `AlertFeature`
- `AuthFeature`
- `RegisterFlowFeature`
- `CalendarFeature`
- `FavoritesFeature`
- `MapFeature`
- `OnboardingFeature`
- `PopupRequestFeature`
- `PopupRequestManagementFeature`
- `PopupRequestManagementDetailFeature`
- `ProfileFeature`
- `ReviewFeature`
- `SearchFeature`

## 권장 전환 순서

### 1차

- `HomeFeature`
- `PopupDetailFeature`

이유:

- 이미 reducer 초안이 존재한다.
- `PopupUsecaseProtocol` 기반 전환 패턴을 먼저 굳히기 좋다.
- coordinator callback 구조를 유지한 채 vertical slice로 진행할 수 있다.

### 2차

- `SearchFeature`
- `AlertFeature`
- `FavoritesFeature`
- `CalendarFeature`

이유:

- `PopupUsecaseProtocol` 소비 패턴이 유사하다.
- 홈/상세에서 검증한 dependency bridge를 재사용하기 좋다.

### 3차

- `AuthFeature`
- `RegisterFlowFeature`
- `ProfileFeature`
- `PopupRequestFeature`
- `PopupRequestManagementFeature`
- `OnboardingFeature`

이유:

- user/admin flow는 popup list 계열보다 상태 책임이 다르다.
- 세션, 인증, 관리자 동선이 묶여 있어 별도 묶음으로 보는 편이 안전하다.

### 마지막

- `MapFeature`

이유:

- 위치 정보
- bottom sheet 두 개
- category/filter/detail 상태
- 지도 중심 좌표

복잡도가 가장 높아 별도 대형 작업으로 다루는 편이 좋다.

## 현재 issue 매핑

- `#28` umbrella / 설계용 refactor issue
- `#29` HomeFeature TCA 1차 전환
- `#30` HomeFeature TCA 2차 전환
- `#31` PopupDetailFeature TCA 전환
- `#32` PopupUsecase 소비 feature 1차 전환
- `#33` User/Admin feature 2차 전환
- `#34` MapFeature TCA 전환
- `#35` PopupUsecaseProtocol 분리와 Coordinator TCA 전환 필요성 검토

새 issue가 추가되거나 번호가 바뀌면 이 section을 업데이트한다.

## Feature별 migration 체크 포인트

### HomeFeature

- data loading / filter / sort / like를 reducer 기준으로 정리
- sheet state ownership 구분
- deeplink timing 정리
- 광고 삽입 로직과 store state 경계 점검

### PopupDetailFeature

- related popup loading
- optimistic like update
- admin deactivate flow
- home과 동일한 dependency bridge 패턴 정렬

### PopupUsecase 소비 feature

- `SearchFeature`
- `AlertFeature`
- `FavoritesFeature`
- `CalendarFeature`

공통 체크:

- popup list state
- loading / error state
- like state synchronization
- coordinator callback 유지 여부

### User/Admin feature

- 인증/회원가입
- 프로필/설정
- 제보/관리 화면

공통 체크:

- user/admin usecase 분리
- session 관련 state
- 화면별 async state 전이

### MapFeature

- first/second bottom sheet ownership
- user location / map center state ownership
- filter state와 detail state 분리
- coordinator로 올릴 state와 feature 내부 state 구분

## TCA 전환이 끝난 뒤 검토할 구조 변경

- `PopupUsecaseProtocol` 세분화 필요 여부
- coordinator를 TCA store 기반으로 올릴 필요 여부
- 문서 기준선 갱신

이 항목은 `#35` 또는 후속 spike issue에서만 다루는 것을 기본값으로 삼는다.
