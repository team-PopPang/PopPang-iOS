# Feature Migration Inventory

이 문서는 PopPang의 Compound -> TCA 전환 현황, Coordinator 제거 방향, issue 기반 우선순위를 기록한다.

migration이 진행되면 이 문서를 함께 업데이트한다.

## 기준 시점

- 작성 기준: 2026-06-14
- 활성 코드 기준: 루트 `Projects/*`

## 현재 상태 요약

### Navigation 전환 기준

- Coordinator 패턴은 제거 완료된 legacy 구조다.
- 화면 전환용 escaping closure는 제거 대상이다.
- root/auth/sheet/fullScreen은 tree-based navigation으로 모델링한다.
- push/drill-down은 stack-based navigation으로 모델링한다.
- tree-based navigation에서 여러 destination이 있으면 `@Reducer enum Destination`과 단일 `@Presents var destination`을 사용한다.
- stack-based navigation은 `@Reducer enum Path`와 `StackState<Path.State>`를 사용한다.
- 자세한 기준은 `Docs/tca-navigation-guidelines.md`를 따른다.

### TCA 예시가 이미 존재하는 feature

- `AuthFeature`
- `RegisterFlowFeature`
- `CalendarFeature`
- `FavoritesFeature`
- `MapFeature`
- `OnboardingFeature`
- `AlertFeature`
- `ReviewFeature`
- `HomeFeature`
  - `HomeFeatureReducer`
  - `ComingPopupDetailReducer`
- `ProfileFeature`
- `PopupDetailFeature`
  - `PopupDetailFeatureReducer`
- `SearchFeature`

### Compound 기반 feature

- `PopupRequestFeature`
- `PopupRequestManagementFeature`
- `PopupRequestManagementDetailFeature`

## 권장 전환 순서

### 1차

- `AppFeature` / root navigation
- `MainTabFeature` navigation 정리
- `HomeFeature`
- `PopupDetailFeature`

이유:

- Coordinator 제거 이후 navigation ownership을 안정화하는 진입점이다.
- `MainTabFeature`에 이미 `StackState` 기반 초안이 있다.
- 이미 reducer 초안이 존재한다.
- `PopupUsecaseProtocol` 기반 전환 패턴을 먼저 굳히기 좋다.
- 화면 전환용 escaping closure 제거 패턴을 검증하기 좋다.

### 2차

- `SearchFeature`
- `AlertFeature`

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

## 현재 issue 매핑

- `#28` umbrella / 설계용 refactor issue
- `#29` HomeFeature TCA 전환
- `#30` PopupDetailFeature TCA 전환
- `#31` SearchFeature TCA 전환
- `#32` FavoritesFeature TCA 전환
- `#33` AlertFeature TCA 전환
- `#34` CalendarFeature TCA 전환
- `#35` MapFeature TCA 전환
- `#37` ReviewFeature TCA 전환
- `#38` AuthFeature TCA 전환
- `#39` OnboardingFeature TCA 전환
- `#40` ProfileFeature TCA 전환
- `#41` PopupRequestFeature TCA 전환
- `#42` PopupRequestManagementFeature TCA 전환
- `#43` AdFeature TCA 적용 범위 검토
- `#44` TCA Dependency Client 규칙 표준화
- `#45` App dependency bootstrap 이전 준비
- `#46` Coordinator TCA 전환

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
- 화면 전환용 escaping closure 제거 여부
- delegate action으로 parent navigation intent 전달

### User/Admin feature

- 인증/회원가입
- 프로필/설정
- 제보/관리 화면

공통 체크:

- user/admin usecase 분리
- session 관련 state
- 화면별 async state 전이
- root/auth tree-based navigation 영향

### MapFeature

- first/second bottom sheet ownership
- user location / map center state ownership
- filter state와 detail state 분리
- parent reducer로 올릴 navigation intent와 feature 내부 state 구분
- `NaverMapCoordinator` SDK bridge와 화면 전환 coordinator를 구분
- feature-scoped dependency client와 SDK callback bridge 경계를 분리

## TCA 전환이 끝난 뒤 검토할 구조 변경

- `PopupUsecaseProtocol` 세분화 필요 여부
- `Shared.Models`, `Shared.Clients`, `Shared.Caches` 분리 필요 여부
- `SharedFeature` 분리 필요 여부
- 문서 기준선 갱신

이 항목은 navigation ownership과 escaping routing 제거가 안정화된 뒤 후속 spike issue에서 다룬다.
