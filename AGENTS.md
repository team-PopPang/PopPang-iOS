# AGENTS.md

## Codex 빠른 시작

이 저장소에서 코드를 수정하기 전에 이 파일을 먼저 읽는다.

목차:

- 빠른 시작
- 커밋 규칙
- Tuist 사용법
- 현재 모듈화 진행 상태
- 목표와 문제 정의
- 아키텍처 원칙
- MVI 상태 관리
- 디렉터리 구조와 레이어 책임
- Coordinator 전략
- NMapsMap 전략
- 마이그레이션 단계
- PopPang 적용 가이드

## 커밋 규칙

커밋 메시지는 한 줄 subject 기준으로 작성한다.

기본 형식:

- `타입: 한글 문장`

메시지 언어 규칙:

- 타입 키워드는 영어로 유지한다.
- 콜론 뒤 설명 문장은 반드시 한글로 작성한다.
- 코드 식별자, 모듈명, 라이브러리명은 필요할 때만 원문 영어를 유지한다.

예시:

- `feat: 홈 피처 스캐폴드 추가`
- `fix: 초기 diffable 리스트 렌더링 문제 수정`
- `chore: Tuist 템플릿 갱신`
- `docs: AGENTS 가이드 정리`
- `refactor: 루트 코디네이터 분리`
- `test: 검색 피처 최근 검색어 테스트 추가`

권장 type:

- `feat`: 사용자 기능 추가
- `fix`: 버그 수정
- `chore`: 설정, 스크립트, 유지보수 작업
- `refactor`: 동작 변화 없는 구조 개선
- `docs`: 문서 변경
- `test`: 테스트 추가 또는 수정

이 저장소에서는 아래 타입만 사용한다:

- `fix`: 일반적인 버그 수정
- `chore`: 기타 작업, 설정, 스크립트, 유지보수
- `feat`: 새로운 기능 개발
- `refactor`: 코드 리팩토링
- `test`: 테스트 코드 작성 및 수정
- `docs`: 문서 작성 및 수정

이모지 라벨 기준:

- `✨ feat`
- `🔧 fix`
- `⚙️ chore`
- `🔨 refactor`
- `✅ test`
- `📃 docs`

## 저장소 운영 규칙

- 커밋 메시지는 `타입: 한글 문장` 형식을 사용한다.
- 타입은 `feat`, `fix`, `chore`, `refactor`, `docs`, `test` 중 하나만 사용한다.
- 예: `fix: 초기 diffable 리스트 렌더링 문제 수정`
- 변경량이 많을 때는 중간중간 커밋한다.
- 커밋 단위는 파일 단위를 우선한다. 하나의 파일 변경이 단독으로 설명 가능하면 파일 하나만 stage해서 커밋한다.

로컬 전용 스크립트:

- `./scripts/ai_commit_push.sh "feat: Tuist 피처 템플릿 추가"`

동작:

- `git add .`
- `git commit -m "입력한 메시지"`
- `git push`

## Tuist 사용법

Tuist 버전은 `4.115.0`으로 고정한다.

템플릿 명령은 기본적으로 저장소 루트에서 실행한다.

기본 명령:

- 설치 버전 확인: `tuist version`
- 사용 가능한 템플릿 확인: `tuist scaffold list`
- 프로젝트 생성: `tuist generate`
- stale generated project 정리 후 재생성: `make regen`
- 빌드 산출물만 빠르게 정리: `make trash`
- 로컬 빌드 산출물, Xcode DerivedData, Tuist 캐시 정리: `make clean`
- `clean` 후 `tuist install`, `tuist generate`까지 다시 수행: `make reinstall`
- Makefile 도움말: `make module-help`
- 로컬 커밋/푸시 스크립트: `./scripts/ai_commit_push.sh "feature: 홈 피처 추가"`

템플릿 옵션 원칙:

- 재사용 feature용 인터페이스는 같은 feature 프로젝트 안의 `...FeatureInterface` 타깃으로 만든다.
- `make module LAYER=feature NAME=PopupDetail INTERFACE=true`를 실행하면 같은 `Project.swift` 안에 구현 타깃과 인터페이스 타깃을 함께 생성한다.
- 이 제어는 `Tuist/Package.swift`가 아니라 `Tuist/Templates/feature-module`과 `Makefile`에서 관리한다.
- 새로 생성하는 모든 모듈의 기본 `deploymentTargets`는 `iOS 17.0`이다.
- 새로 생성하는 모든 모듈의 기본 `destinations`는 `iPhone` 전용이다. `iPad`, `mac`, `macCatalyst`는 기본으로 열어두지 않는다.

레이어별 스캐폴드 명령:

- App 모듈: `tuist scaffold app-module --name AppSession`
- Coordinator 모듈: `tuist scaffold coordinator-module --name Root`
- Feature 모듈: `tuist scaffold feature-module --name Home`
- 재사용 Feature 타깃 포함 모듈: `tuist scaffold feature-module --name PopupDetail --include-interface true`
- Domain 모듈: `tuist scaffold domain-module --name Popup`
- Data 모듈: `tuist scaffold data-module --name Popup`
- ThirdParty 모듈: `tuist scaffold third-party-module --name Firebase`
- Core 모듈: `tuist scaffold core-module --name HTTPClient`
- DSKit 모듈: `tuist scaffold dskit-module --name DSKit`
- Shared 모듈: `tuist scaffold shared-module --name UIComponents`

Makefile 래퍼 명령:

- `make module LAYER=app NAME=AppSession`
- `make module LAYER=coordinator NAME=Root`
- `make module LAYER=feature NAME=Home`
- `make module LAYER=feature NAME=PopupDetail INTERFACE=true`
- `make module LAYER=domain NAME=Popup`
- `make module LAYER=data NAME=Popup`
- `make module LAYER=thirdparty NAME=Firebase`
- `make module LAYER=core NAME=HTTPClient`
- `make module LAYER=dskit NAME=DSKit`
- `make module LAYER=shared NAME=UIComponents`
- `make regen`
- `make trash`
- `make clean`
- `make reinstall`

스캐폴드 결과 규칙:

- `feature-module`은 `Projects/Features/{Name}Feature`를 생성한다.
- `feature-module`은 기본적으로 `{Name}FeatureDemo` 앱 타깃과 `{Name}FeatureTests` 타깃을 함께 만든다.
- 재사용성이 높은 feature는 같은 project 안에 `{Name}FeatureInterface` 타깃을 추가한다.
- 현재 우선 예시는 `PopupDetailFeature`, `SearchFeature`다.
- `coordinator-module`은 `Projects/Coordinator/{Name}Coordinator`를 생성한다.
- `domain-module`, `data-module`, `third-party-module`은 레이어 이름에 맞는 suffix를 붙여 생성한다.

우선 규칙:

1. 새 코드를 추가하기 전에 이 문서의 아키텍처 방향을 먼저 따른다.
2. 사용자가 커밋해달라고 하면 가능하면 `./scripts/ai_commit_push.sh "type: message"` 스크립트를 우선 사용한다.
3. 커밋 메시지는 타입 키워드만 영어로 쓰고, 설명 문장은 반드시 한글로 작성한다.
4. 기본 구조는 `App / Coordinator / Features / Domain / Data / ThirdParty / Core / DSKit / Shared`를 우선한다.
5. `Coordinator`는 하나의 거대한 코디네이터가 아니라 `전역 coordinator + feature coordinator` 구조로 본다.
6. `Feature`는 `Data`에 직접 의존하지 않는다. 구현체보다 `Domain`에 의존한다.
7. feature 상태 관리는 `indextrown/Compound`의 MVI 패턴을 기본으로 차용한다.
8. route는 가볍게 유지한다. route 타입 안에 `Binding`, `View`, 무거운 closure를 넣지 않는다.
9. `FeatureInterface`는 기본값으로 모든 feature에 두지 않는다. 재사용성이 높은 feature에만 선택적으로 도입한다.
10. `NMapsMap` 연동은 선언형으로 유지한다. 콜백이 많은 생성자보다 SwiftUI 스타일의 modifier 체이닝을 우선한다.
11. 외부 SDK SPM product는 `ThirdParty` 타깃에서만 직접 `.external(...)`로 링크한다. `App`, `Coordinator`, `Feature`, `Data`, `Core`, `DSKit`은 필요한 경우 `ThirdParty` 프로젝트 타깃에 의존한다.
12. Swift 소스에서는 `import ThirdParty`로 SDK 모듈 사용 사실을 숨기지 않는다. `ThirdParty`에 의존하더라도 실제 SDK 타입을 직접 쓰는 파일은 `import Moya`, `import Kingfisher`, `import KakaoSDKShare`, `import NMapsMap`처럼 실제 라이브러리 모듈명을 명시한다.
13. `ThirdParty`는 외부 SDK import를 `@_exported`로 재노출하지 않는다. `ThirdParty`는 wrapper 레이어가 아니라 외부 라이브러리 링크 허브다.
14. V0 기능 이식은 대응되는 `V0/` 코드를 먼저 복사한 뒤 모듈 경계와 `Compound` 구조에 맞게 수정한다. 임의로 새 구현을 정제하거나 재해석하지 않는다.
15. 구조 개선보다 V0 기능 동일성을 우선한다. V0 코드가 이미 동작하는 기준이므로 먼저 그대로 옮기고, 이후 컴파일/의존성/상태 관리에 필요한 최소 변경만 한다.
16. `Projects/App/Project.swift`의 App 타깃은 항상 다크모드를 지원하지 않도록 `UIUserInterfaceStyle`을 `Light`로 둔다.
17. App 타깃은 로컬라이징 fallback이 영어로 고정되지 않도록 `CFBundleDevelopmentRegion=ko`, `CFBundleLocalizations=[ko,en,ja]`, `CFBundleAllowMixedLocalizations=true`를 유지한다.
18. feature 단위 타입에는 `@MainActor`를 습관적으로 붙이지 않는다. SwiftUI가 관찰하는 state/store, UIKit/SwiftUI API 접근, 메인 스레드 UI 갱신처럼 실제 메인 액터 격리가 필요한 경우에만 붙인다.
19. 변경 사항이 이 문서와 충돌하면, 문서를 함께 갱신하거나 왜 다르게 가야 하는지 명시한다.

저장소 방향:

- 이 프로젝트는 단일 타깃 Xcode 앱에서 `Tuist` 기반 micro feature architecture로 마이그레이션 중이다.
- 모듈 경계, coordinator 배치, 마이그레이션 방향은 이 문서를 기준 문서로 사용한다.
- 현재 지향 아키텍처는 `MVI + Clean Architecture + Coordinator + Modular Architecture` 조합이다.
- `V0/` 폴더는 기존 레거시 프로젝트 보관 및 참고 전용이다.
- 새 모듈러 작업은 루트의 `Projects/`, `Tuist/`, `Makefile` 기준으로 진행한다.
- 사용자가 명시적으로 요청하지 않으면 `V0/` 내부 파일은 수정하지 않고 참고만 한다.

참고:

- 벤치마크 레포: https://github.com/sergdort/ModernCleanArchitectureSwiftUI
- MVI 참고 레포: https://github.com/indextrown/Compound
- Tuist 고정 버전: `4.115.0` (`.tuist-version` 사용)

## 현재 모듈화 진행 상태

기준 시점:

- 마지막 점검 기준일: `2026-05-22`
- 점검 기준 범위: `Projects/`, `V0/`, `Workspace.swift`, 각 레이어 `Project.swift`

현재 판정:

- `Workspace`와 `Tuist` 기반 멀티 모듈 뼈대는 생성되어 있다.
- `App / Coordinator / Features / Domain / Data / Shared` 기본 레이어는 연결되어 있다.
- `V0` 기능의 실질 이식은 아직 초기 단계이며, 다수 feature는 placeholder 화면 수준이다.
- `Domain`은 V0 엔티티/프로토콜/유스케이스 위임 구현을 상당수 옮겼다.
- `Core`, `DSKit`은 V0 공통 코드 일부를 이미 모듈로 추출했다.
- `App` 조립 계층과 실제 세션/루트 흐름 복원은 아직 미완료다.
- `Data` 레이어는 구현 이식 중이므로 사용자 작업 중 변경과 충돌하지 않게 주의한다.

추가 판정:

- 현재 루트 앱은 "샘플 coordinator 모음" 단계를 벗어나야 하며, 목표는 "V0와 동일 기능 집합을 가지는 모듈러 앱"이다.
- 따라서 placeholder 화면이 하나라도 남아 있으면 마이그레이션 완료로 간주하지 않는다.
- `V0`와의 parity 기준은 "화면 존재"가 아니라 "진입 경로, 상태 변화, 주요 액션, 외부 연동, 부가 플로우까지 동일하게 동작"이다.
- `App`, `Coordinator`, `Features`, `Data`, `Shared` 어느 레이어에서든 V0 기능 유실이 발견되면 체크리스트에 즉시 반영한다.

### V0 전체 도입 체크리스트

완료:

- [x] `Workspace.swift`가 `Projects/App`, `Projects/Coordinator`, `Projects/Features`, `Projects/Domain`, `Projects/Data`, `Projects/Shared`를 포함한다.
- [x] `App` 타깃이 `Coordinator`, `Domain`, `Data`, `ThirdParty`, `Core`, `DSKit`에 의존한다.
- [x] `Coordinator` 타깃이 전역 흐름과 feature coordinator 뼈대를 가진다.
- [x] `Auth`, `Onboarding`, `Home`, `Search`, `PopupDetail`, `Map`, `Calendar`, `Favorites`, `Profile`, `Alert`, `Review` feature 프로젝트가 생성되어 있다.
- [x] `SearchFeatureInterface`, `PopupDetailFeatureInterface` 선택형 인터페이스 타깃이 존재한다.
- [x] `Domain`에 V0 엔티티, repository protocol, usecase protocol, usecase implementation 기본 이식이 들어가 있다.
- [x] `Core`에 네트워크, 로컬 저장소, 로깅, Foundation 확장 일부가 추출되어 있다.
- [x] `DSKit`에 V0 디자인 시스템 컴포넌트 다수가 추출되어 있다.

진행 중:

- [x] `App` 레이어에 V0 `DIContainer`를 대체하는 모듈 조립 전용 `AppCore` 구성을 완성한다.
- [x] 앱 시작 시 v0처럼 비로그인은 온보딩 플로우, 인증 사용자는 메인 플로우로 분기하는 세션/부트스트랩 흐름을 복원한다.
- [x] `Coordinator`에서 placeholder 런치/전환 버튼 기반 흐름을 제거하고 실제 앱 상태 기반 흐름으로 바꾼다.
- [ ] `HomeFeature`, `SearchFeature`, `PopupDetailFeature`, `MapFeature`, `CalendarFeature`, `FavoritesFeature`, `ProfileFeature`, `AlertFeature`, `ReviewFeature`, `AuthFeature`, `OnboardingFeature` 각각에 V0 화면/상태/내비게이션을 이식한다.
- [x] 각 feature의 placeholder `Text("...Feature")` 화면을 실제 V0 UI 또는 점진 이식용 컨테이너로 교체한다.
- [x] `Feature -> Domain` 의존만 사용하도록 유스케이스 주입 경로를 통일한다.
- [x] feature 내부 상태를 `Compound` 기반 `Action / Mutation(or Reaction) / State` 구조로 실제 유스케이스와 연결한다.
- [x] `MapFeature`에 NMapsMap 브리지를 선언형 modifier/DSL 중심 구조로 정리해 이식한다.
- [x] `Coordinator`의 route를 순수 intent 값으로 정리하고 `Binding`/무거운 closure 의존을 V0에서 제거한 형태로 치환한다.
- [x] `MainTab` 각 탭의 사용자 세션 전달 방식을 `EnvironmentObject` 남용 없이 정리한다.
- [x] 로그인, 회원가입, 자동 로그인, 로그아웃, FCM 토큰, 딥링크 흐름을 App/Coordinator/Feature 경계에 맞게 재배치한다.
- [ ] `Data` 레이어를 V0 repository 구현과 DTO/mapper 기준으로 안정화한다.
- [x] `ThirdParty` 의존성 선언과 실제 SDK 사용 지점을 추적 가능하게 정리한다.
- [ ] `V0`에서 아직 남아 있는 공통 유틸/UI 확장을 `Core` 또는 `DSKit`로 분류 이전한다.
- [ ] 각 feature demo 앱이 실제 대표 화면과 샘플 데이터를 보여주도록 보강한다.
- [ ] 레이어별 테스트를 placeholder 수준에서 실제 시나리오 검증으로 확장한다.

### V0 기능 동일성 체크 기준

- [ ] V0의 모든 사용자 진입점이 모듈러 앱에서 재현된다.
- [ ] V0의 모든 주요 탭과 서브플로우가 동일한 목적지와 상태 전이를 가진다.
- [ ] V0의 로그인 상태, 회원가입 상태, 온보딩 완료 상태, 자동 로그인 상태가 동일한 저장소 의미를 가진다.
- [ ] V0의 팝업 탐색, 상세, 찜, 캘린더, 지도, 프로필, 알림, 리뷰 흐름이 동일한 유스케이스 결과를 만든다.
- [ ] V0의 딥링크, FCM 토큰, 공유, 외부 링크, 문의 메일, 약관 이동이 모두 다시 연결된다.
- [ ] V0의 디자인 토큰, 폰트, 공통 버튼/셀/시트 스타일이 DSKit 또는 feature component로 복원된다.
- [ ] V0와 비교해 기능이 빠졌거나 동작이 달라진 부분은 "의도된 변경"으로 문서화되지 않는 한 미완료다.

### V0 화면/기능 매트릭스

앱/루트:

- [x] `LaunchView` 로딩 후 비로그인은 온보딩 플로우, 인증 사용자는 메인 플로우로 자동 분기
- [x] 자동 로그인 성공/실패 분기
- [x] 회원가입 진행 중 `register` 단계 유지
- [x] 로그아웃 후 비로그인 온보딩 플로우 복귀

온보딩/인증:

- [x] `OnboadringView` 3단계 페이지, skip, next, start
- [x] `LoginView` 카카오/애플/구글 로그인
- [x] `RegisterFlowView` 전체 스텝 전환
- [x] `NicknameSettingView` 닉네임 검증
- [x] `CategorySettingView` 추천 카테고리 선택
- [x] `KeywordSettingView` 알림 키워드 설정

메인 탭:

- [x] `HomeView` 추천/오픈예정/검색 진입
- [x] `SearchView` 검색 입력, 최근 검색, 결과 리스트
- [x] `PopupDetailView` 상세 정보, 찜, 공유, 외부 링크
- [x] `ComingPopupDetailView` 오픈 예정 상세
- [x] `CalendarView` 달력, 날짜별 팝업 목록
- [x] `MapView` 지도, 필터, 클러스터링, 시트 전환
- [x] `FavoriteView` 리스트/캘린더 모드
- [x] `ProfileView` 설정/알림/문의/약관/로그아웃
- [x] `AlertView` 활동 알림과 키워드 알림
- [x] `Review` 관련 작성/조회 플로우

공통/인프라:

- [x] `MainTabView` 탭 상태와 각 탭별 세션 전달
- [ ] `Coordinator` 기반 push/sheet/fullScreen/bottomSheet parity
- [x] `KakaoShareManager`, 외부 URL, 문의 메일
- [x] `UserDefaultsManager`의 최근 검색어, FCM 토큰, 딥링크 popup id
- [x] `FirebaseAnalytics` 또는 대체 추적 연결

### V0 파일 단위 parity 체크리스트

App:

- [x] `V0/PopPang/Sources/App/PopPangApp.swift`
- [x] `V0/PopPang/Sources/App/RootViewModel.swift`
- [x] `V0/PopPang/Sources/App/RootViewSwitcher.swift`
- [x] `V0/PopPang/Sources/App/DIContainer/DIContainer.swift`
- [x] `V0/PopPang/Sources/App/DIContainer/ViewModelFactory.swift`
- [ ] `V0/PopPang/Sources/App/Coordinator/Coordinator/MainCoordinator/1. MainRoute.swift`
- [ ] `V0/PopPang/Sources/App/Coordinator/Coordinator/MainCoordinator/2. SheetRoute.swift`
- [ ] `V0/PopPang/Sources/App/Coordinator/Coordinator/MainCoordinator/3. OverlayRoute.swift`
- [x] `V0/PopPang/Sources/App/Coordinator/Coordinator/MainCoordinator/4. FullScreenRoute.swift`
- [ ] `V0/PopPang/Sources/App/Coordinator/Coordinator/MainCoordinator/5. BottomSheetRoute.swift`
- [x] `V0/PopPang/Sources/App/Coordinator/Coordinator/OnboardingCoordinator/OnboardingRoute.swift`

Onboarding/Auth:

- [x] `V0/PopPang/Sources/Presentation/Launch/LaunchView.swift`
- [x] `V0/PopPang/Sources/Presentation/Onboarding/OnboadringView.swift`
- [x] `V0/PopPang/Sources/Presentation/Onboarding/OnboardingStep.swift`
- [x] `V0/PopPang/Sources/Presentation/Login/LoginView.swift`
- [x] `V0/PopPang/Sources/Presentation/Login/LoginFlow/RegisterFlowView.swift`
- [x] `V0/PopPang/Sources/Presentation/Login/LoginFlow/NicknameSettingView.swift`
- [x] `V0/PopPang/Sources/Presentation/Login/LoginFlow/CategorySettingView.swift`
- [x] `V0/PopPang/Sources/Presentation/Login/LoginFlow/KeywordSettingView.swift`

MainTab/Home/Search/PopupDetail:

- [x] `V0/PopPang/Sources/Presentation/MainTab/MainTabView.swift`
- [x] `V0/PopPang/Sources/Presentation/MainTab/MainTabType.swift`
- [x] `V0/PopPang/Sources/Presentation/MainTab/Tabs/Home/HomeView.swift`
- [x] `V0/PopPang/Sources/Presentation/MainTab/Tabs/Home/HomeViewModel.swift`
- [x] `V0/PopPang/Sources/Presentation/MainTab/Tabs/Home/0. Search/SearchView.swift`
- [x] `V0/PopPang/Sources/Presentation/MainTab/Tabs/Home/0. Search/SearchViewModel.swift`
- [x] `V0/PopPang/Sources/Presentation/MainTab/Tabs/Home/2. PopupDetail/PopupDetailView.swift`
- [x] `V0/PopPang/Sources/Presentation/MainTab/Tabs/Home/2. PopupDetail/PopupDetailViewModel.swift`
- [x] `V0/PopPang/Sources/Presentation/MainTab/Tabs/Home/5. ComingPopupDetail/ComingPopupDetailView.swift`
- [x] `V0/PopPang/Sources/Presentation/MainTab/Tabs/Home/3. Cell/BestPopupCell.swift`
- [x] `V0/PopPang/Sources/Presentation/MainTab/Tabs/Home/3. Cell/ComingPopupCell.swift`
- [x] `V0/PopPang/Sources/Presentation/MainTab/Tabs/Home/3. Cell/GridPopupCell.swift`
- [x] `V0/PopPang/Sources/Presentation/MainTab/Tabs/Home/4. UI/BookmarkButton.swift`

Calendar/Favorites:

- [x] `V0/PopPang/Sources/Presentation/MainTab/Tabs/Calendar/CalendarView.swift`
- [x] `V0/PopPang/Sources/Presentation/MainTab/Tabs/Calendar/CalendarViewModel.swift`
- [x] `V0/PopPang/Sources/Presentation/MainTab/Tabs/Calendar/UI/CalendarPopupCell.swift`
- [x] `V0/PopPang/Sources/Presentation/MainTab/Tabs/Calendar/UI/CalendarPopupListView.swift`
- [x] `V0/PopPang/Sources/Presentation/MainTab/Tabs/Favorite/FavoriteView.swift`
- [x] `V0/PopPang/Sources/Presentation/MainTab/Tabs/Favorite/FavoriteViewModel.swift`
- [x] `V0/PopPang/Sources/Presentation/MainTab/Tabs/Favorite/FavoriteList/FavoriteListView.swift`
- [x] `V0/PopPang/Sources/Presentation/MainTab/Tabs/Favorite/FavoriteCalendar/FavoriteCalendarView.swift`

Map:

- [x] `V0/PopPang/Sources/Presentation/MainTab/Tabs/Map/MapView.swift`
- [x] `V0/PopPang/Sources/Presentation/MainTab/Tabs/Map/MapViewModel.swift`
- [x] `V0/PopPang/Sources/Presentation/MainTab/Tabs/Map/Clustering/MapCoordinator.swift`
- [x] `V0/PopPang/Sources/Presentation/MainTab/Tabs/Map/Clustering/ItemKey.swift`
- [x] `V0/PopPang/Sources/Presentation/MainTab/Tabs/Map/Cell/MapListPopupCell.swift`
- [x] `V0/PopPang/Sources/Presentation/MainTab/Tabs/Map/TrendingCategories/TrendingCategory.swift`
- [x] `V0/PopPang/Sources/Presentation/MainTab/Tabs/Map/TrendingCategories/TrendingCategoryChip.swift`
- [x] `V0/PopPang/Sources/Presentation/MainTab/Tabs/Map/TrendingCategories/TrendingCategoryScrollView.swift`
- [x] `V0/PopPang/Sources/Presentation/MainTab/Tabs/Map/UI/Sheet/FirstSheetView.swift`
- [x] `V0/PopPang/Sources/Presentation/MainTab/Tabs/Map/UI/Sheet/SecondSheeetView.swift`
- [x] `V0/PopPang/Sources/Presentation/MainTab/Tabs/Map/UI/Sheet/DetailSheetView.swift`

Alert/Profile/Review:

- [x] `V0/PopPang/Sources/Presentation/MainTab/Tabs/Alert/AlertView.swift`
- [x] `V0/PopPang/Sources/Presentation/MainTab/Tabs/Alert/Activity/ActivityView.swift`
- [x] `V0/PopPang/Sources/Presentation/MainTab/Tabs/Alert/Activity/ActivityViewModel.swift`
- [x] `V0/PopPang/Sources/Presentation/MainTab/Tabs/Alert/Keyword/KeywordView.swift`
- [x] `V0/PopPang/Sources/Presentation/MainTab/Tabs/Alert/Keyword/KeywordViewModel.swift`
- [x] `V0/PopPang/Sources/Presentation/MainTab/Tabs/Profile/ProfileView.swift`
- [x] `V0/PopPang/Sources/Presentation/MainTab/Tabs/Profile/ProfileViewModel.swift`
- [x] `V0/PopPang/Sources/Presentation/MainTab/Tabs/Profile/SubView/0. ProfileSettingView.swift`
- [x] `V0/PopPang/Sources/Presentation/MainTab/Tabs/Profile/SubView/1. NotificationView.swift`
- [x] `V0/PopPang/Sources/Presentation/MainTab/Tabs/Profile/SubView/2. SupportEmail.swift`
- [x] `V0/PopPang/Sources/Presentation/MainTab/Tabs/Profile/SubView/3. ServiceTermsView.swift`
- [x] `V0 review detail/write flow`

### Route parity 체크리스트

- [x] `MainRoute.alert(uuid:)`
- [x] `MainRoute.popupDetail(_:_: )`
- [x] `MainRoute.comingPopupDetail`
- [x] `MainRoute.profileSetting`
- [x] `MainRoute.notification`
- [x] `MainRoute.service`
- [x] `MainRoute.reviewDetail(_:)`
- [x] `SheetRoute.regionSheet`
- [x] `SheetRoute.sortSheet`
- [x] `FullScreenRoute.search(uuid:)`
- [x] `BottomSheetRoute.popupDetailSheet`

### Feature 완료 기준

- [x] `HomeFeature`는 알림 진입, 검색 진입, 오픈 예정 상세, 지역/정렬 상태, 딥링크 popup 이동 기준을 모두 가진다.
- [x] `SearchFeature`는 최근 검색어, 검색어 입력, 결과 필터링, 상세 이동을 가진다.
- [x] `PopupDetailFeature`는 찜, 공유, 외부 링크, 리뷰 목록/상세/작성 진입을 가진다.
- [x] `CalendarFeature`는 달력 선택과 날짜별 팝업 목록을 가진다.
- [x] `FavoritesFeature`는 찜리스트/찜캘린더 세그먼트와 알림 진입을 가진다.
- [x] `MapFeature`는 검색, 지역, 카테고리, 현재 위치 이동, 1차/2차 시트 전환을 가진다.
- [x] `ProfileFeature`는 알림센터 진입, 프로필 설정, 공지사항, 문의하기, 약관, 알림 토글, 로그아웃을 가진다.
- [x] `AlertFeature`는 활동/키워드 세그먼트와 편집 상태를 가진다.
- [x] `ReviewFeature`는 리뷰 리스트, 상세, 작성 흐름을 가진다.

### 심화 마이그레이션 체크리스트

App:

- [x] `AppCore`가 V0 `DIContainer`의 조립 책임을 대체한다.
- [x] 세션 저장소가 `uuid`, 온보딩 완료 여부, 푸시/딥링크 초기 상태를 보존한다.
- [x] 앱 부트스트랩이 앱 실행 직후 필요한 preload를 중앙에서 결정한다.

Coordinator:

- [x] 루트 coordinator가 V0 `RootScene` 전환과 동등한 상태 머신을 가진다.
- [ ] 인증 플로우와 메인 플로우의 경계를 route 값과 navigator protocol로 고정한다.
- [ ] 전역 sheet/overlay/fullScreen/bottomSheet는 feature 로컬 상태와 전역 상태를 분리한다.
- [x] `register`처럼 인증 내부 다단계 흐름은 root 또는 auth 전용 coordinator에 명확히 배치한다.

Features:

- [x] 각 feature는 placeholder 문구 대신 실제 V0 화면 구조 또는 점진 이식 컨테이너를 가진다.
- [x] 각 feature는 `Action/Reaction/State`와 실제 usecase 호출이 연결된다.
- [ ] 다른 feature 이동은 직접 view import가 아니라 route/factory/navigator를 통해 연결한다.
- [ ] feature 내부 공통 셀/섹션/버튼은 feature component 또는 DSKit으로 분리한다.

Domain/Data:

- [ ] V0 usecase protocol과 repository protocol의 의미 차이가 없는지 검증한다.
- [x] V0 DTO, mapper, API endpoint를 Data에 재배치하면서 응답 필드 유실이 없는지 확인한다.
- [ ] 자동 로그인, 회원가입, 닉네임 체크, 팝업 조회, 찜 변경, 리뷰, 알림이 실제 구현체에 연결된다.

Shared:

- [ ] `DSKit`이 V0 폰트, 색, 버튼, 시트, 셀 스타일을 흡수한다.
- [ ] `Core`가 네트워크, 로컬 저장소, logger, formatter, Foundation 확장을 정리한다.
- [x] `ThirdParty`는 SDK 사용처를 추적 가능하게 유지한다.

테스트/검증:

- [x] App launch state 테스트
- [x] Root/MainTab coordinator 전환 테스트
- [ ] feature reducer/usecase 테스트
- [ ] repository contract 테스트
- [ ] 핵심 사용자 플로우 UI test

완료 조건:

- [ ] `V0/PopPang/Sources/Presentation`의 사용자 기능이 모두 `Projects/Features/*` 또는 `Projects/Coordinator/*`에서 동등 기능으로 동작한다.
- [ ] `V0/PopPang/Sources/App`의 조립/루트 흐름/DI 책임이 모두 `Projects/App`과 `Projects/Coordinator`로 이전된다.
- [ ] `V0` 의존 없이 `tuist generate` 후 모듈 앱이 기본 사용자 플로우를 실행할 수 있다.
- [x] placeholder feature 화면과 임시 전환 버튼이 제거된다.
- [ ] 각 레이어의 의존성 금지 규칙 위반이 없고, 테스트 가능한 경계가 확보된다.

### 구현 순서 체크리스트

1. `App` 조립 계층부터 고정한다.
   - 세션 저장소
   - 온보딩 완료 여부
   - 루트 진입 경로 결정
   - 향후 DI registry 자리 마련
2. `Coordinator` 루트 흐름을 실제 앱 상태 기반으로 바꾼다.
   - launch 자동 전이
   - onboarding/auth/main 진입
   - 로그아웃 복귀
3. `Auth + Onboarding`을 먼저 이식한다.
   - 로그인
   - 회원가입
   - 온보딩 완료 저장
4. `MainTab` 기준 핵심 사용자 가치 순서대로 이식한다.
   - `Home`
   - `PopupDetail`
   - `Search`
   - `Map`
   - `Favorites`
   - `Calendar`
   - `Profile`
   - `Alert`
   - `Review`
5. `Data`와 `ThirdParty`를 각 feature 요구사항에 맞춰 수렴시킨다.
6. demo/test/딥링크/푸시/분석까지 마이그레이션 완료 기준을 맞춘다.

# PopPang Tuist Micro Feature Architecture Spec

## 1. 목표

PopPang을 단일 Xcode 프로젝트 구조에서 `Tuist` 기반의 `micro feature architecture`로 전환한다.

아키텍처 방향 요약:

- `MVI`: feature 상태 관리
- `Clean Architecture`: 계층 분리와 의존성 방향 통제
- `Coordinator`: 앱 흐름과 화면 이동 관리
- `Modular Architecture`: 레이어별/기능별 모듈 분리

이번 전환의 핵심 목적은 다음과 같다.

1. 기능별 독립 개발이 가능한 모듈 구조를 만든다.
2. 빌드 범위를 줄여 개발 속도와 프리뷰 생산성을 높인다.
3. 현재 `Coordinator + EnvironmentObject` 중심 네비게이션의 과도한 뷰 갱신 문제를 줄인다.
4. 도메인 규칙, 데이터 구현, UI 기능을 분리해서 변경 영향 범위를 축소한다.
5. 장기적으로 `feature 단위 오너십`, `병렬 개발`, `테스트 분리`, `릴리즈 안정성`을 확보한다.

이 문서는 `sergdort/ModernCleanArchitectureSwiftUI`의 계층 분리 방향을 PopPang의 현재 구조와 요구사항에 맞게 구체화한 설계 명세다.

Tuist 버전은 `4.115.0`으로 고정하며, 저장소 루트의 `.tuist-version` 파일을 기준으로 맞춘다.

참고 레포:

- https://github.com/sergdort/ModernCleanArchitectureSwiftUI

핵심 벤치마크 포인트:

- Feature는 Domain과 UI에만 의존한다.
- App은 시작과 조립을 담당한다.
- Coordinator는 앱 흐름과 전역 네비게이션을 담당한다.
- Feature 상태 관리는 `Compound` 스타일 MVI를 따른다.
- Data는 Domain 계약을 구현한다.
- ThirdParty는 외부 SDK adapter와 wrapper를 담당한다.
- DSKit은 공통 디자인 시스템 UI 컴포넌트를 담당한다.
- Core는 네트워크, 저장소, 공통 유틸리티 같은 기반 인프라를 제공한다.

## 2. 현재 구조에서 해결해야 할 문제

현재 프로젝트는 `PopPang/Sources` 내부에 `App`, `Presentation`, `Util`, `DesignSystem`이 한 타깃에 섞여 있다.

### 2.1 Presentation이 너무 큰 단일 덩어리

- `Home`, `Map`, `Favorite`, `Calendar`, `Profile`, `Login`, `Onboarding`이 모두 한 타깃 안에 있다.
- 화면, ViewModel, 화면 전환, 의존성 주입이 물리적으로 분리되어 있지 않다.
- 기능 간 import 경계가 없어 순환성 있는 참조가 늘어나기 쉽다.

### 2.2 Coordinator가 View 생성까지 알아서 담당함

현재 `Coordinator` 확장은 라우트별 `buildView(for:)`를 직접 가진다.

이 구조의 문제:

1. 네비게이션 상태 객체가 화면 생성 책임까지 가진다.
2. 특정 feature 화면 타입을 coordinator가 직접 import하게 된다.
3. coordinator 모듈이 feature 구현 상세에 강하게 결합된다.
4. feature 재사용성이 낮다.

### 2.3 상태 관찰 범위가 넓어서 렌더링 diff에 취약함

현재 `Coordinator`는 하나의 `ObservableObject` 안에서 아래 상태를 모두 `@Published`로 노출한다.

- `paths`
- `sheet`
- `overlay`
- `fullScreen`
- `bottomSheet`
- `bottomSheetPosition`

이 구조는 다음 문제를 유발할 수 있다.

1. sheet 상태 변경만 일어나도 coordinator를 참조하는 다른 뷰 계층이 재평가될 수 있다.
2. 하나의 거대한 navigation state가 모든 presentation 타입을 동시에 품고 있어서 관심사 분리가 약하다.
3. `EnvironmentObject`로 coordinator를 넓게 주입하면 feature 내부의 작은 상호작용도 상위 container diff에 연결되기 쉽다.

### 2.4 Route 정의가 UI 상태와 강하게 결합됨

예를 들면 `SheetRoute`는 `Binding`과 `onDismiss closure`를 직접 가진다.

이 구조의 문제:

- route가 순수한 navigation intent가 아니라 UI runtime state를 함께 가진다.
- 테스트가 어렵다.
- 라우트의 동일성/식별성 판단이 불안정해질 수 있다.
- 네비게이션 레이어가 화면 내부 로컬 상태까지 알아야 한다.

### 2.5 Root 흐름과 인증 흐름이 앱 전체 조립과 섞여 있음

현재 `RootViewModel`, `RootViewSwitcher`, `OnboardingCoordinator`, `MainTabView`가 앱 전체 흐름을 한 타깃에서 직접 조합한다.

이 상태에서는:

- 인증 플로우 분리
- feature preview app 구성
- 독립 테스트
- 추후 app shell / feature shell 분리

가 어려워진다.

### 2.6 NMapsMap의 UIViewRepresentable 브리지가 콜백 중심으로 깊어지고 있음

현재 `NMapsMap`은 `UIViewRepresentable`로 포팅되어 있지만, 상호작용을 외부로 노출하는 방식이 콜백 누적 형태로 커질 가능성이 있다.

이 구조의 문제:

1. 지도 설정과 이벤트 연결 코드가 한 지점에 몰리기 쉽다.
2. `makeUIView` / `updateUIView` / `Coordinator` 내부 책임이 비대해진다.
3. feature에서 지도를 사용할수록 생성자 파라미터와 callback 수가 늘어난다.
4. SwiftUI 뷰처럼 선언적으로 읽히지 않고 imperative bridge 코드가 전면으로 드러난다.
5. 향후 marker, camera, overlay, selection, gesture 처리가 추가될수록 유지보수 비용이 급격히 올라간다.

## 3. 목표 아키텍처 원칙

### 3.1 최상위 분리는 feature 기준

최상위 업무 단위는 레이어가 아니라 feature다. 다만 의존성 방향을 통제하기 위해 내부 모듈은 계층을 가진다.

PopPang 기준 1차 feature 후보:

- `Auth`
- `Onboarding`
- `Home`
- `Search`
- `PopupDetail`
- `Map`
- `Calendar`
- `Favorites`
- `Profile`
- `Alert`
- `Review`

### 3.2 계층 의존성은 단방향

의존성 방향은 아래로만 흐른다.

`App -> Coordinator -> Features -> Domain`

`App -> Data -> Domain -> Core`

`Coordinator -> Features -> Domain`

`Data -> Core -> ThirdParty`

Feature는 Data를 직접 import하지 않는다.

### 3.3 각 모듈은 하나의 이유로만 변경되어야 함

- Feature: 화면/사용자 플로우 변경
- Domain: 비즈니스 규칙 변경
- Data: 외부 API/DB/SDK 구현 변경
- ThirdParty: 외부 라이브러리/SDK adapter, wrapper, bridge 변경
- Core: 공통 인프라 구현 변경
- App: 앱 시작, 조립, 환경 구성 변경
- Coordinator: 앱 흐름, 전역 네비게이션, feature 간 연결 변경

### 3.4 Route는 순수 intent여야 한다

Route에 `Binding`, `View`, `closure`, 거대한 DTO를 넣지 않는다.

허용:

- 식별자
- 경량 value
- 탐색에 필요한 파라미터

예:

```swift
public enum HomeRoute: Hashable {
    case search
    case popupDetail(id: Popup.ID)
    case alertCenter
}
```

비권장:

```swift
case regionSheet(
    regions: [RegionList],
    selectedRegion: Binding<RegionList?>,
    selectedDistrict: Binding<String?>,
    onDismiss: (() -> Void)?
)
```

### 3.5 Feature 상태 관리는 MVI를 기본으로 한다

PopPang의 feature 상태 관리는 `indextrown/Compound` 레포의 구조를 기본으로 차용한다.

참고:

- https://github.com/indextrown/Compound

핵심 개념:

- `Action`: 화면에서 들어오는 사용자 의도
- `Mutation`: 상태를 어떻게 바꿀지 나타내는 값
- `State`: 화면이 관찰하는 현재 상태
- `mutate(action:)`: action을 하나 이상의 mutation stream으로 변환
- `reduce(state:mutation:)`: mutation을 적용해 다음 state 생성

기본 흐름:

```text
View -> send(Action) -> mutate(Action) -> AsyncStream<Mutation> -> reduce(State, Mutation) -> State
```

원칙:

- feature의 화면 상태는 가능하면 하나의 `State`로 모은다.
- 사용자 이벤트는 `Action`으로 표현한다.
- side effect 경계는 `mutate(action:)`에 둔다.
- 상태 전이 규칙은 `reduce(state:mutation:)`에 둔다.
- 현재 state를 기준으로 한 계산은 가능하면 `reduce`에서 처리한다.
- 하나의 action에서 여러 중간 상태가 필요하면 `AsyncStream<Mutation>`으로 순차 반영한다.
- `Compound` 1.0.4 이상에서는 토스트, 얼럿, dismiss, 네비게이션, sheet 표시처럼 한 번 발생하고 소비되는 UI 신호를 `@Trigger`로 표현한다.
- `@Trigger`는 같은 값을 다시 대입해도 새로운 발생으로 취급하므로, 반복 탭/반복 오류 메시지/동일 route 재표시가 필요한 곳에 우선 적용한다.
- persistent UI 상태는 일반 `State` 값으로 둔다. `@Trigger`는 전체 상태 저장소 대체가 아니라 one-shot signal 전용으로만 사용한다.

## 4. 목표 디렉터리 구조

```text
.
├── App
│   ├── Project.swift
│   ├── Sources
│   └── Resources
├── Projects
│   ├── App
│   │   ├── AppCore
│   ├── Coordinator
│   │   ├── RootCoordinator
│   │   ├── MainTabCoordinator
│   │   ├── AuthFlowCoordinator
│   │   ├── Presentation
│   │   └── Contracts
│   ├── Features
│   │   ├── AuthFeature
│   │   ├── OnboardingFeature
│   │   ├── HomeFeature
│   │   ├── SearchFeature
│   │   ├── PopupDetailFeature
│   │   ├── MapFeature
│   │   ├── CalendarFeature
│   │   ├── FavoritesFeature
│   │   ├── ProfileFeature
│   │   ├── AlertFeature
│   │   └── ReviewFeature
│   ├── Domain
│   │   ├── AuthDomain
│   │   ├── UserDomain
│   │   ├── PopupDomain
│   │   ├── MapDomain
│   │   ├── FavoritesDomain
│   │   ├── ReviewDomain
│   │   └── NotificationDomain
│   ├── Data
│   │   ├── AuthData
│   │   ├── UserData
│   │   ├── PopupData
│   │   ├── ReviewData
│   │   ├── PopupCacheData
│   │   ├── UserCacheData
│   │   ├── NotificationData
│   │   └── AnalyticsData
│   └── Shared
│       ├── ThirdParty
│       │   ├── FirebaseSDK
│       │   ├── KakaoSDK
│       │   ├── GoogleSignInSDK
│       │   ├── NMapsSDK
│       │   └── KingfisherSDK
│       ├── Core
│       │   ├── HTTPClient
│       │   ├── LocalStorage
│       │   ├── FileCache
│       │   ├── Logging
│       │   ├── ConcurrencyKit
│       │   └── FoundationExtensions
│       └── DSKit
│           ├── DesignToken
│           ├── Typography
│           ├── ButtonKit
│           ├── TagKit
│           └── SheetKit
├── Tuist
│   ├── Package.swift
│   ├── ProjectDescriptionHelpers
│   └── Templates
└── Workspace.swift
```

원칙:

- `Projects/Features/*`가 최상위 사용자 경험 단위다.
- `Projects/Domain/*`은 기능 공통 비즈니스 규칙을 담는다.
- `Projects/Data/*`는 외부 구현체다.
- `Projects/Shared/ThirdParty/*`는 외부 SDK adapter, wrapper, bridge를 담는다.
- 현재 PopPang은 `ThirdParty`를 외부 SDK 의존성 허브로도 사용한다. 외부 SDK SPM product의 직접 `.external(...)` 링크는 `Projects/Shared/ThirdParty/Project.swift`에만 둔다.
- `ThirdParty`에 의존하는 모듈은 필요 시 `import ThirdParty`가 아니라 `import FirebaseCore`, `import Moya`, `import Kingfisher`처럼 실제 라이브러리 모듈명을 직접 import한다.
- `Projects/Shared/Core/*`는 어떤 업무 문맥에도 속하지 않는 기반 기술이다.
- `Projects/Shared/DSKit/*`는 디자인 시스템 토큰과 공통 UI 컴포넌트를 담는다.
- `Projects/App/*`는 앱 시작, DI 조립, 환경 구성을 담당한다.
- `Projects/Coordinator/*`는 루트 흐름, 탭 흐름, feature 간 연결, 전역 presentation을 담당한다.

## 5. 레이어별 책임

### 5.1 App Layer

책임:

- 앱 엔트리포인트
- 전역 DI 조립
- 환경 설정(dev/staging/prod)
- analytics, push, deep link 연결

후보 모듈:

- `AppCore`: 전역 dependency registry, session state, app settings

주의:

- App이 business rule을 가지면 안 된다.
- Feature의 내부 state machine을 App이 직접 건드리면 안 된다.
- App이 navigation orchestration의 중심이 되면 안 된다.

### 5.1A Coordinator Layer

책임:

- Root scene 전환
- 인증 플로우 전환
- 탭 구성과 탭 전환
- feature 간 navigation orchestration
- deep link 라우팅
- 전역 sheet, fullScreen, overlay 관리

후보 모듈:

- `RootCoordinator`
- `MainTabCoordinator`
- `AuthFlowCoordinator`
- `PresentationStores`
- `NavigationContracts`

주의:

- Coordinator는 business rule을 가지면 안 된다.
- Coordinator는 API 호출, repository 접근, DTO 처리를 하면 안 된다.
- Coordinator는 feature 내부 세부 state를 소유하면 안 된다.

### 5.2 Features Layer

책임:

- 화면 단위 유스케이스 조합
- 화면 상태 관리
- 사용자 액션 처리
- 화면 렌더링
- feature 내부 로컬 navigation

지도처럼 UIKit bridge 성격이 강한 UI도 feature에서는 "조립된 SwiftUI 인터페이스"로 소비할 수 있어야 한다.
즉, feature는 Naver Map SDK의 세부 연결 방식보다 `MapFeature용 DSL` 또는 `modifier 기반 API`를 보게 만드는 것이 목표다.

상태 관리 원칙:

- feature 내부 상태는 `Compound` 스타일 MVI를 기본으로 한다.
- feature는 `Action / Mutation / State` 구조를 우선 검토한다.
- 비동기 로딩, 로딩 시작/종료, 에러 반영처럼 중간 상태가 필요한 경우 `AsyncStream<Mutation>`을 활용한다.

권장 내부 구조:

```text
HomeFeature
├── Sources
│   ├── Presentation
│   │   ├── HomeRootView.swift
│   │   ├── HomeView.swift
│   │   ├── HomeAction.swift
│   │   ├── HomeMutation.swift
│   │   ├── HomeState.swift
│   │   └── HomeStore.swift
│   ├── Components
│   └── Navigation
│       ├── HomeRoute.swift
│       └── HomeNavigating.swift
└── Tests
```

선택 규칙:

- 기본 feature는 `Interface` 없이 `public RootView`를 직접 외부에 노출한다.
- `PopupDetailFeature`, `SearchFeature`처럼 재사용성이 높은 feature만 같은 프로젝트 안에 `{Name}FeatureInterface` 타깃을 선택적으로 둔다.

규칙:

- Feature는 자신의 화면과 화면 상태만 안다.
- 다른 feature의 View 타입을 직접 생성하지 않는다.
- 다른 feature 이동은 `Navigator protocol` 또는 `FeatureFactory protocol`로 위임한다.

### 5.3 Domain Layer

책임:

- Entity
- Value Object
- Repository protocol
- Gateway protocol
- UseCase protocol / implementation
- 비즈니스 규칙

예시:

`PopupDomain`

- `Popup`
- `PopupSummary`
- `PopupFilter`
- `PopupRepository`
- `FetchPopupListUseCase`
- `FetchPopupDetailUseCase`
- `ToggleFavoritePopupUseCase`

규칙:

- SwiftUI import 금지
- Firebase/Moya/Google/Kakao import 금지
- DB 모델, DTO 직접 노출 금지

### 5.4 Data Layer

책임:

- Domain의 protocol 구현
- API DTO 정의
- DB Entity 정의
- mapping
- repository composition

예시:

`PopupData`

- `PopupRemoteDataSource`
- `PopupDTO`
- `PopupResponseMapper`
- `DefaultPopupRepository`

규칙:

- Feature를 import하지 않는다.
- 구현체는 Domain protocol을 만족해야 한다.
- Data는 필요한 외부 SDK를 사용할 수 있지만, 타깃 의존성은 직접 `.external(...)`이 아니라 `ThirdParty` 프로젝트 의존성으로 받는다.

### 5.4A ThirdParty Layer

책임:

- 외부 SDK SPM product 직접 링크 집약
- 외부 SDK 의존성 선언
- SDK를 어디서 쓰는지 추적 가능한 경계 제공

예시:

- `FirebaseSDK`
- `KakaoSDK`
- `GoogleSignInSDK`
- `NMapsSDK`
- `KingfisherSDK`

규칙:

- ThirdParty는 비즈니스 규칙을 가지면 안 된다.
- ThirdParty는 Domain usecase를 알면 안 된다.
- 현재 PopPang에서는 ThirdParty에 wrapper/adapter를 기본 전략으로 두지 않는다.
- `ThirdParty`는 SDK 모듈을 `@_exported import`로 재노출하지 않는다.
- App, Coordinator, Feature, Data, Core, DSKit은 필요한 SDK 타입을 직접 쓸 때 SDK 모듈명을 직접 `import`해서 사용한다.
- ThirdParty는 "어떤 외부 라이브러리를 프로젝트에서 쓸 수 있는지"와 "어디에서 외부 SDK가 링크되는지"를 모아두는 의존성 허브로 본다.
- wrapper를 만들지 않을 SDK는 `ThirdParty` 안에 빈 marker 타입을 두지 않는다. 이 경우 `ThirdParty`는 의존성 집약 레이어 역할만 맡는다.
- feature 전용 브리지는 재사용성이 낮으면 feature 내부에 둘 수 있다.

### 5.5 Core Layer

책임:

- HTTP client
- cache abstraction
- persistence helper
- logging
- date/formatter helper
- test utility
- concurrency utility

현재 Core 내부 분류:

- `Network`: `Moya` 기반 공통 네트워크 토대, base URL, provider, decode helper
- `LocalStorage`: `UserDefaults` 기반 로컬 저장소와 저장소별 helper
- `Logging`: 콘솔 로그 출력과 로그 포맷
- `FoundationExtensions`: 순수 Foundation 확장
- `Support`: marker, shared primitive, 공통 지원 타입

V0 기준으로 Core에 넣을 우선 후보:

- 이미 반영한 항목
  - `Data/Infrastructure/Remote/Network/NetworkProvider.swift`
    - `Moya` 기반 provider
    - async request decode helper
  - `Data/Infrastructure/Local/UserDefaultsManager.swift`
    - 최근 검색어 저장
    - FCM 토큰 저장
    - 딥링크 popup id 저장
  - `Data/Infrastructure/Local/Logger.swift`
    - 콘솔 로거 포맷
  - `Util/Extensions+/DateFormatter+.swift`
    - 공통 date/time formatter
  - `Util/Extensions+/String+.swift`
    - `shortAddress`
  - `Util/Constants/Constants.swift` 중 순수 상수
    - `apiURL`
    - `imageURL`
    - 외부 링크 상수
    - 유니버설 링크 base URL

- 아직 Core에 남아 있는 V0 기반 후보
  - `Util/Logger/UILogger.swift`
    - SwiftUI body/diff 디버깅 helper
  - `Util/Constants/Constants.swift` 중 `Bundle.main.infoDictionary` 기반 키 읽기
    - `KAKAO_NATIVE_APP_KEY`
    - `NMFClientID`
  - `Util/Extensions+/UIApplication+.swift`
    - 키보드 내리기 helper

Core에서 제외하는 V0 파일:

- `Util/Logger/FirebaseLogger.swift`
  - FirebaseAnalytics 직접 의존이라 `Core`보다 `App` 또는 실제 화면 사용 지점에 두는 편이 안전
- `Util/Logger/TTT.swift`
  - `#if false` 상태의 실험용 샘플이라 마이그레이션 대상 아님

중요 원칙:

- Core는 먼저 `V0`에 실제로 존재하는 기능을 거의 그대로 옮기는 것을 우선한다.
- `V0`에 없는 개념을 "좋아 보여서" 먼저 추가하지 않는다.
- 예: 현재 `V0`에 `Keychain`, `DateProvider`, `UUIDProvider`, `FileCache`가 없으므로, 당장 Core 체크리스트의 선행 작업으로 넣지 않는다.
- 먼저 해야 하는 일은 `V0`의 기존 동작을 유지한 채 새 모듈 구조로 옮기는 것이다.

후순위 검토 후보:

- `AppConfig`
  - 앱 환경값, plist 값 읽기
- `DateProvider`
  - 현재 시각 의존성 분리
- `UUIDProvider`
  - 식별자 생성 의존성 분리
- `JSONDecoder` / `JSONEncoder` 공통 설정
- `Keychain` 추상화
- `FileCache`
- `Concurrency` helper

Core에 넣지 않는 것:

- `AlertManager`
  - UIKit alert 조립이라 `Coordinator` 또는 `DSKit/Presentation` 성격
- `KFImage+`
  - `Kingfisher`와 UI가 강하게 결합되어 `DSKit` 또는 feature 내부 성격
- `View+`, `UIImage+`, `UINavigationBar+`, `UITabBar+`
  - UI 확장은 `DSKit`
- `LocalizationKeys`
  - 나중에 별도 `Localization` 영역으로 분리
- `DIContainer`
  - 조립 책임이라 `App` 쪽이 더 적합

현재 코드 매핑 예:

- `Util/Logger/*` -> `Core/Logging`
- `Util/Extensions+/*` 중 Foundation/UI 공통 확장 -> `Core/FoundationExtensions` 또는 `DSKit`

추가 원칙:

- 서드파티 UIKit SDK 브리징 자체는 성격에 따라 `ThirdParty`, `Feature 내부 UI bridge`, `Shared UI bridge` 중 하나에 둔다.
- feature는 브리지의 내부 coordinator callback 구조를 직접 다루지 않는다.

## 6. 모듈 의존성 규칙

### 6.1 허용 규칙

- `App -> Coordinator`
- `App -> Domain`
- `App -> Data`
- `App -> ThirdParty`
- `App -> Shared`
- `Coordinator -> Features`
- `Coordinator -> Domain`
- `Coordinator -> Shared`
- `Features -> DSKit`
- `Features -> Domain`
- `Features -> Shared`
- `Features -> ThirdParty`
- `Data -> Domain`
- `Data -> ThirdParty`
- `DSKit -> Core`
- `Core -> ThirdParty`
- `Shared -> Core`

### 6.2 금지 규칙

- `Feature -> Data`
- `Feature -> Coordinator` 직접 구현 의존
- `Domain -> Data`
- `Domain -> ThirdParty`
- `Domain -> Feature`
- `Core -> Domain`
- `FeatureA -> FeatureB` 직접 View import

### 6.3 추천 해결 방식

다른 feature로 이동이 필요할 때:

1. `App`이 `FeatureFactory`를 조립한다.
2. `Coordinator`가 `FeatureFactory`를 통해 화면 흐름을 연결한다.
3. feature는 `Navigator protocol`만 호출한다.
4. 실제 대상 화면 생성은 `Coordinator` 또는 `FeatureFactory`가 맡는다.

## 7. Tuist 설계 원칙

### 7.1 Workspace 구성

- 루트는 `Workspace.swift`
- 각 모듈은 독립 `Project.swift`
- 공통 설정은 `ProjectDescriptionHelpers`로 추출

예시:

```swift
// Workspace.swift
import ProjectDescription

let workspace = Workspace(
    name: "PopPang",
    projects: [
        "App",
        "Projects/App/**",
        "Projects/Coordinator/**",
        "Projects/Features/**",
        "Projects/Domain/**",
        "Projects/Data/**",
        "Projects/Shared/**"
    ]
)
```

### 7.2 타깃 원칙

각 모듈은 가능하면 아래 중 하나를 가진다.

- `static framework`
- `dynamic framework`
- `unit tests`

초기 전략:

- 대부분 `static framework`
- 리소스 많은 feature만 상황 보고 `dynamic framework`

### 7.3 Helper 도입

`ProjectDescriptionHelpers`에 아래 helper를 둔다.

- `makeFeatureModule`
- `makeCoordinatorModule`
- `makeDomainModule`
- `makeDataModule`
- `makeThirdPartyModule`
- `makeCoreModule`
- `makeDSKitModule`
- `makeSharedModule`

이유:

- 타깃 선언 반복 제거
- 의존성 규칙을 helper 레벨에서 반강제
- 신규 feature 생성 속도 향상

## 8. Coordinator 개선 명세

현재 구조의 가장 큰 개선 지점은 "coordinator가 너무 많은 상태를 한 번에 관찰시킨다"는 점이다.

추가로 중요한 설계 결정은 다음이다.

- coordinator를 전부 feature 밖에 둘지
- coordinator를 전부 feature 안에 둘지

PopPang에서는 둘 중 하나만 고르기보다, `전역 Coordinator + Feature Coordinator`의 이중 구조를 채택한다.

### 8.1 개선 목표

1. navigation state를 presentation 타입별로 분리한다.
2. route는 순수 값으로 유지한다.
3. coordinator는 view factory가 아니라 state holder + intent dispatcher로 축소한다.
4. screen 생성 책임은 `Coordinator` 또는 `FeatureFactory`로 이동한다.
5. feature 내부에서는 필요한 navigator만 주입한다.

### 8.1A 최종 배치 원칙

#### 전역 Coordinator가 맡는 일

- 앱 시작 흐름
- 인증 여부에 따른 루트 전환
- 온보딩 -> 로그인 -> 메인 진입
- 메인 탭 구성 및 탭 전환
- feature A -> feature B 이동
- deep link 처리
- 전역 sheet, fullScreen, overlay

#### Feature Coordinator가 맡는 일

- 해당 feature 내부 push
- 해당 feature 내부 sheet
- 해당 feature 내부 fullScreen
- 해당 feature 내부 selection flow
- 해당 feature 내부 화면 조립

핵심 판단 기준:

- `앱 전체 흐름`이면 전역 Coordinator
- `그 feature 안에서만 끝나는 흐름`이면 Feature Coordinator

### 8.1B 왜 이렇게 나누는가

#### 전역에만 모두 둘 경우 문제

- coordinator가 거대해진다.
- 모든 feature 화면을 다 알아야 한다.
- 결합도가 커진다.
- 지금 겪는 diff/render 범위 문제도 같이 커지기 쉽다.

#### feature 안에만 모두 둘 경우 문제

- 로그인 -> 메인 전환 같은 루트 흐름 책임이 애매해진다.
- 탭 전환 책임이 분산된다.
- feature 간 이동 규칙이 중복되기 쉽다.
- deep link와 전역 presentation 관리가 어려워진다.

그래서 PopPang은 다음 구조가 가장 적합하다.

```text
App
Coordinator
Features
Domain
Data
Core
Shared
```

여기서:

- `App`은 시작과 조립
- `Coordinator`는 앱 흐름 orchestration
- `Features`는 각 기능의 로컬 흐름

### 8.1C PopPang 기준 실제 예시

#### 예시 1. 앱 시작

```text
PopPangApp
 -> RootCoordinatorView
   -> 인증 안 됨: AuthFeature 시작
   -> 인증 됨: MainTabCoordinator 시작
```

이 경우는 앱 전체 루트 흐름이므로 전역 Coordinator 책임이다.

#### 예시 2. 메인 탭

```text
MainTabCoordinator
 - HomeFeature
 - MapFeature
 - FavoritesFeature
 - ProfileFeature
```

탭 자체는 앱 전체 구조이므로 전역 Coordinator가 담당한다.

#### 예시 3. 홈 목록에서 팝업 상세 이동

```text
HomeView
 -> HomeCoordinator.push(.popupDetail(id))
```

`홈 목록 -> 홈 상세`는 HomeFeature 내부 흐름이므로 `HomeCoordinator` 책임이다.

#### 예시 4. 홈에서 검색 화면 진입

이건 두 가지 선택지가 있다.

1. 검색을 HomeFeature 내부 하위 흐름으로 보면 `HomeCoordinator`
2. 검색을 독립 Feature로 보고 여러 곳에서 재사용하면 전역 Coordinator

PopPang에서는 `SearchFeature`를 독립 feature로 둘 예정이므로, 장기적으로는 전역 Coordinator가 연결하는 편이 더 적합하다.

```text
HomeViewModel
 -> AppCoordinator.showSearch()
```

#### 예시 5. 프로필에서 로그아웃

```text
ProfileView
 -> ProfileViewModel.logoutTapped()
 -> RootCoordinator.showAuthFlow()
```

로그아웃은 앱 루트를 바꾸므로 전역 Coordinator 책임이다.

#### 예시 6. 맵에서 바텀시트 열기

```text
MapView
 -> MapCoordinator.present(.popupDetailSheet(id))
```

맵 내부 바텀시트는 MapFeature 내부 흐름이므로 `MapCoordinator` 책임이다.

### 8.1D 추천 Coordinator 모듈 구조

```text
Coordinator
├── RootCoordinator
├── MainTabCoordinator
├── AuthFlowCoordinator
├── Presentation
│   ├── StackNavigationStore
│   ├── SheetPresentationStore
│   ├── OverlayPresentationStore
│   └── FullScreenPresentationStore
└── Contracts
    ├── RootNavigating
    ├── TabNavigating
    └── GlobalPresentationRouting
```

그리고 각 feature 내부에는 로컬 흐름 전용 coordinator를 둘 수 있다.

```text
Features
├── HomeFeature
│   ├── Interface
│   └── Sources
│       ├── Presentation
│       └── Navigation
│           ├── HomeCoordinator
│           ├── HomeRoute
│           └── HomeNavigating
├── MapFeature
│   └── Navigation
│       ├── MapCoordinator
│       └── MapRoute
└── ProfileFeature
    └── Navigation
        ├── ProfileCoordinator
        └── ProfileRoute
```

### 8.1E 이해하기 쉬운 코드 예시

#### 전역 Coordinator 프로토콜 예시

```swift
@MainActor
public protocol RootCoordinating {
    func showAuthFlow()
    func showMainFlow()
    func showSearch()
}
```

이 프로토콜은 루트 전환이나 cross-feature 이동처럼 앱 전체 흐름에 해당하는 액션을 담당한다.

#### Feature Coordinator 프로토콜 예시

```swift
@MainActor
public protocol HomeCoordinating {
    func showPopupDetail(id: String)
    func showLocalFilterSheet()
}
```

이 프로토콜은 HomeFeature 내부에서만 끝나는 화면 흐름을 담당한다.

#### HomeViewModel 예시

```swift
@MainActor
final class HomeViewModel {
    private let rootCoordinator: RootCoordinating
    private let homeCoordinator: HomeCoordinating

    init(
        rootCoordinator: RootCoordinating,
        homeCoordinator: HomeCoordinating
    ) {
        self.rootCoordinator = rootCoordinator
        self.homeCoordinator = homeCoordinator
    }

    func didTapPopup(id: String) {
        homeCoordinator.showPopupDetail(id: id)
    }

    func didTapSearch() {
        rootCoordinator.showSearch()
    }

    func didTapFilter() {
        homeCoordinator.showLocalFilterSheet()
    }
}
```

이 예시의 의미:

- 같은 feature 내부 이동은 `homeCoordinator`
- 다른 feature 또는 앱 전체 흐름 이동은 `rootCoordinator`

### 8.1F 역할 분리 규칙

#### 전역 Coordinator는 하지 말아야 할 것

- API 호출
- repository 접근
- business logic 처리
- feature 내부 세부 state 소유
- 모든 화면 구현을 직접 아는 거대한 switch 유지

#### Feature Coordinator는 하지 말아야 할 것

- 앱 전체 루트 전환 결정
- 메인 탭 구조 소유
- 다른 feature 구현 세부 조립
- 인증 세션 판단

### 8.1G PopPang 적용 가이드

초기에는 다음처럼 시작한다.

- `RootCoordinator`: `launch`, `auth`, `main`
- `MainTabCoordinator`: 홈/지도/찜/프로필 탭
- `HomeCoordinator`: 홈 내부 상세/필터/로컬 시트
- `MapCoordinator`: 지도 내부 바텀시트/선택 흐름
- `ProfileCoordinator`: 프로필 내부 설정/약관/알림 화면

이렇게 시작하면:

- 현재처럼 하나의 coordinator가 모든 화면을 직접 아는 구조를 줄일 수 있다.
- feature 응집도를 유지하면서도 루트 흐름은 안정적으로 관리할 수 있다.

### 8.2 목표 구조

```text
Coordinator
├── RootCoordinator
├── MainTabCoordinator
├── AuthFlowCoordinator
└── PresentationStores
    ├── StackNavigationStore
    ├── SheetPresentationStore
    ├── OverlayPresentationStore
    └── FullScreenPresentationStore
```

### 8.3 권장 구현 방향

#### A. 하나의 거대 Coordinator를 없애고 Presentation Store로 분리

예:

```swift
@Observable
public final class StackNavigationStore<Route: Hashable> {
    public var path: [Route] = []

    public func push(_ route: Route) {
        path.append(route)
    }

    public func pop() {
        guard !path.isEmpty else { return }
        path.removeLast()
    }
}
```

```swift
@Observable
public final class SheetPresentationStore<Route: Identifiable> {
    public var route: Route?

    public func present(_ route: Route) {
        self.route = route
    }

    public func dismiss() {
        route = nil
    }
}
```

장점:

- `sheet` 변경이 `path` 변경 관찰자에 덜 영향을 준다.
- 프레젠테이션 종류별로 테스트가 쉬워진다.
- 필요 store만 주입할 수 있다.

#### B. Feature는 Navigator protocol만 본다

예:

```swift
@MainActor
public protocol HomeNavigating {
    func showSearch()
    func showPopupDetail(id: Popup.ID)
    func showAlertCenter()
}
```

```swift
@Observable
public final class HomeViewModel {
    @ObservationIgnored
    private let navigator: HomeNavigating

    public init(navigator: HomeNavigating) {
        self.navigator = navigator
    }

    func didTapSearch() {
        navigator.showSearch()
    }
}
```

장점:

- Home feature는 SearchView를 몰라도 된다.
- route, view assembly, transition 스타일 결정은 상위 레이어가 가진다.

#### C. buildView는 Coordinator extension이 아니라 Router/Factory에서 담당

현재:

- `Coordinator where T == MainRoute`가 직접 `PopupDetailView()` 등을 생성

목표:

- `MainRouteViewFactory`
- `HomeFeatureFactory`
- `ProfileFeatureFactory`

처럼 분리한다.

예:

```swift
public protocol HomeFeatureBuilding {
    associatedtype Screen: View
    @MainActor
    func makeHomeScreen() -> Screen
}
```

또는 type erasure:

```swift
@MainActor
public protocol AnyFeatureScreenFactory {
    func makeHomeScreen() -> AnyView
    func makeSearchScreen() -> AnyView
}
```

실전 권장:

- 외부 공개 인터페이스에서는 `some View`보다 `Feature screen wrapper` 또는 `typed root view` 선호
- 필요 시에만 `AnyView` 사용

#### D. Route는 경량 값만 가진다

현재 `SheetRoute`의 `Binding`, `closure` 포함 방식은 제거한다.

대신:

```swift
public enum MapSheetRoute: Identifiable, Equatable {
    case regionSelector(selectedRegionID: String?, selectedDistrictID: String?)
    case sortSelector(selectedSort: SortOption)

    public var id: String {
        switch self {
        case let .regionSelector(regionID, districtID):
            "region-\(regionID ?? "nil")-\(districtID ?? "nil")"
        case let .sortSelector(sort):
            "sort-\(sort.rawValue)"
        }
    }
}
```

선택 결과는 route에 closure를 담지 않고 아래 중 하나로 되돌린다.

1. feature viewModel action
2. shared selection state
3. navigator callback protocol
4. async flow coordinator

#### E. 가능하면 `ObservableObject`보다 Observation 기반 검토

SwiftUI 최신 구조에서는 `@Observable` 기반 상태 분리가 더 자연스럽다.

검토 기준:

- 전역 공유 store: `@Observable`
- UIKit/Firebase/SDK bridge: 기존 class + actor 조합 허용
- ViewModel이 `ObservableObject`를 유지해야 한다면 범위를 좁힌다.

### 8.4 Root 전환도 별도 네비게이션 상태로 분리

현재 `RootViewModel.scene`은 인증 상태와 scene 전환을 모두 포함한다.

목표:

- `AppSessionStore`: 인증 사용자/토큰/권한 상태
- `RootFlowController`: `launch`, `auth`, `main` 흐름 선택

예:

```swift
enum RootFlow: Equatable {
    case launch
    case authentication
    case onboarding
    case main
}
```

이렇게 분리하면 인증 상태와 루트 화면 구성 책임을 나눌 수 있다.

## 8A. NMapsMap SwiftUI DSL 전환 명세

`NMapsMap`은 단순히 `UIViewRepresentable`로 감싼 것에 그치지 않고, 최종적으로는 SwiftUI modifier스럽게 읽히는 선언형 인터페이스로 수렴해야 한다.

### 8A.1 목표

1. 지도 초기화 파라미터를 생성자에 몰아넣지 않는다.
2. 이벤트 연결을 callback 나열 방식 대신 modifier 체이닝으로 노출한다.
3. `MapFeature`는 SDK 타입보다 `PopPangMap`의 공개 인터페이스를 사용한다.
4. 지도 상태와 지도 이벤트를 분리한다.
5. 카메라, 마커, 선택 상태, 오버레이를 선언형 값으로 투입할 수 있게 한다.

### 8A.2 지양할 형태

```swift
NMapsMapView(
    markers: markers,
    selectedMarkerID: selectedMarkerID,
    onTapMarker: { marker in
        ...
    },
    onTapMap: { point in
        ...
    },
    onCameraChanged: { camera in
        ...
    },
    onIdle: {
        ...
    }
)
```

문제:

- 생성자 인자가 비대해진다.
- 콜백이 많아질수록 읽기와 유지보수가 어려워진다.
- SwiftUI스럽지 않다.

### 8A.3 목표 인터페이스 예시

```swift
PopPangMap(camera: cameraState, markers: markers)
    .mapStyle(.default)
    .showsUserLocation(true)
    .selectedMarker(selectedMarkerID)
    .onMarkerTap { markerID in
        viewModel.send(.didTapMarker(markerID))
    }
    .onMapTap { coordinate in
        viewModel.send(.didTapMap(coordinate))
    }
    .onCameraChanged { state in
        viewModel.send(.cameraChanged(state))
    }
    .onCameraIdle {
        viewModel.send(.cameraIdle)
    }
```

핵심은 `SwiftUI View modifier처럼 읽히는 공개 API`를 제공하는 것이다.

### 8A.4 권장 구조

```text
MapFeature
├── Interface
│   └── PopPangMap.swift
├── Sources
│   ├── MapContainerView.swift
│   ├── MapConfiguration.swift
│   ├── MapEventHandlers.swift
│   ├── MapCameraState.swift
│   ├── MapMarkerModel.swift
│   └── Internal
│       ├── NaverMapRepresentable.swift
│       ├── NaverMapCoordinator.swift
│       └── NaverMapRenderer.swift
```

역할 분리:

- `PopPangMap`: 외부 공개 SwiftUI API
- `MapConfiguration`: modifier 결과를 누적하는 설정 값
- `MapEventHandlers`: 탭, 카메라, selection 등 이벤트 핸들러 묶음
- `NaverMapRepresentable`: 실제 `UIViewRepresentable` bridge
- `NaverMapCoordinator`: SDK delegate 수신
- `NaverMapRenderer`: marker/overlay/camera 적용 로직

### 8A.5 구현 원칙

#### A. modifier는 값을 누적하고, bridge는 최종 설정만 적용한다

예:

```swift
public struct PopPangMap: View {
    private var configuration: MapConfiguration

    public init(
        camera: MapCameraState,
        markers: [MapMarkerModel]
    ) {
        self.configuration = MapConfiguration(
            camera: camera,
            markers: markers
        )
    }

    public var body: some View {
        NaverMapRepresentable(configuration: configuration)
    }
}
```

```swift
public extension PopPangMap {
    func onMarkerTap(_ action: @escaping (String) -> Void) -> Self {
        var copy = self
        copy.configuration.onMarkerTap = action
        return copy
    }
}
```

이 패턴을 따르면 외부에서는 modifier처럼 쓰고, 내부에서는 설정 객체를 통해 bridge가 일관되게 동작한다.

#### B. SDK delegate 이벤트는 Coordinator 안에서 끝내고, 바깥에는 도메인 친화적 이벤트만 내보낸다

예:

- `NMFMarker`를 그대로 외부에 주지 않는다.
- `NMGLatLng`를 바로 feature 전체에 퍼뜨리지 않는다.

대신:

- `MarkerID`
- `MapCoordinate`
- `MapCameraState`

같은 앱 친화 타입으로 변환해서 전달한다.

#### C. updateUIView는 diff 적용 지점으로 제한한다

`updateUIView`에서 모든 marker를 매번 갈아끼우는 식이 아니라, 가능한 한 다음을 분리한다.

1. camera 변경
2. marker set 변경
3. selected marker 변경
4. overlay visibility 변경

즉, representable은 "전체 재구성"보다 "부분 적용 renderer" 구조를 목표로 한다.

#### D. feature의 viewModel은 map SDK가 아니라 feature action을 중심으로 동작한다

예:

```swift
enum MapAction {
    case didTapMarker(String)
    case didTapMap(MapCoordinate)
    case cameraChanged(MapCameraState)
    case cameraIdle
}
```

이렇게 해야 feature 테스트가 쉬워지고, 맵 SDK 변경 영향이 작아진다.

### 8A.6 배치 원칙

두 가지 방향 중 하나를 택한다.

1. `MapFeature` 내부의 전용 UI 인프라로 둔다.
2. 다른 feature에서도 재사용할 가능성이 높으면 `DSKit` 또는 `Shared/MapUI`로 분리한다.

현 시점 추천:

- 초기에는 `MapFeature` 내부에 둔다.
- API가 안정되고 재사용처가 생기면 shared module로 승격한다.

### 8A.7 초반 리팩터링 순서

1. 현재 `UIViewRepresentable` 브리지에서 생성자 파라미터와 callback 목록을 정리한다.
2. callback들을 `MapEventHandlers`로 먼저 묶는다.
3. 그 다음 modifier API로 외부 표면을 교체한다.
4. marker/camera/selection diff renderer를 분리한다.
5. 마지막으로 feature 외부 SDK 타입 노출을 제거한다.

## 9. Feature 내부 템플릿

각 feature는 최소 아래 구조를 따른다.

```text
FeatureNameFeature
├── Sources
│   ├── Presentation
│   │   ├── FeatureNameRootView.swift
│   │   ├── FeatureNameView.swift
│   │   ├── FeatureNameStore.swift
│   │   ├── FeatureNameAction.swift
│   │   ├── FeatureNameMutation.swift
│   │   ├── FeatureNameState.swift
│   │   └── FeatureNameViewModel.swift
│   ├── Components
│   ├── Models
│   └── Navigation
│       ├── FeatureNameNavigator.swift
│       └── FeatureNameRoute.swift
├── Interface
│   └── FeatureNameEntryView.swift
└── Tests
```

원칙:

- 기본값은 `FeatureInterface` 없이 feature 모듈이 직접 `public RootView`를 노출하는 방식이다.
- `Interface` 폴더는 모든 feature에 강제하지 않는다.
- `FeatureInterface` 타깃은 `PopupDetailFeature`, `SearchFeature`처럼 재사용성이 높은 feature에만 선택적으로 둔다.
- `Interface`를 둘 경우 외부 모듈이 알아야 하는 최소 표면만 둔다.
- 내부 구현은 `Sources`로 숨긴다.
- 외부에서 feature를 쓸 때는 `Factory`나 `AnyView`가 아니라 `typed RootView` 또는 `EntryView`만 본다.

## 9A. MVI 명세

### 9A.1 기본 방향

PopPang은 feature 상태 관리에서 `MVVM에 Action/Mutation/State 흐름을 결합한 MVI 스타일`을 사용한다.

구현 기준은 `Compound`의 다음 특성을 참고한다.

- `send(Action)`
- `mutate(action:) -> AsyncStream<Mutation>`
- `reduce(state:mutation:) -> State`
- `@Published state`

### 9A.2 추천 역할 분리

- `View`: 상태 렌더링, 사용자 입력 전달
- `Store` 또는 `Compound`: action 수신, mutation 생성, state 전이 관리
- `Coordinator`: 화면 이동 담당
- `UseCase`: 비즈니스 규칙 수행

즉, 상태 변경은 MVI가 맡고, 화면 이동은 Coordinator가 맡는다.

### 9A.3 Coordinator와 MVI의 경계

#### Coordinator가 하는 일

- 다른 화면으로 이동
- 전역 또는 로컬 presentation orchestration

#### MVI Store가 하는 일

- 화면 상태 보관
- action 처리
- 비동기 로딩 중간 상태 방출
- 성공/실패/로딩 상태 전이

규칙:

- navigation 자체를 state mutation으로 과도하게 표현하지 않는다.
- 화면 이동이 필요하면 store가 coordinator protocol을 호출한다.
- coordinator는 state를 직접 바꾸지 않는다.

### 9A.4 예시 코드

```swift
import Compound
import Foundation

@MainActor
final class HomeStore: Compound {
    enum Action: Sendable {
        case onAppear
        case popupTapped(String)
        case refresh
    }

    enum Mutation: Sendable {
        case setLoading(Bool)
        case setItems([PopupSummary])
        case setErrorMessage(String?)
    }

    struct State: Equatable {
        var isLoading = false
        var items: [PopupSummary] = []
        var errorMessage: String?
    }

    @Published var state = State()

    private let fetchHomeItems: FetchHomeItemsUseCase
    private let coordinator: HomeCoordinating

    init(
        fetchHomeItems: FetchHomeItemsUseCase,
        coordinator: HomeCoordinating
    ) {
        self.fetchHomeItems = fetchHomeItems
        self.coordinator = coordinator
    }

    func mutate(action: Action) -> AsyncStream<Mutation> {
        switch action {
        case .onAppear, .refresh:
            return .concat(
                .just(.setLoading(true)),
                AsyncStream { continuation in
                    Task {
                        do {
                            let items = try await fetchHomeItems.execute()
                            continuation.yield(.setItems(items))
                            continuation.yield(.setErrorMessage(nil))
                        } catch {
                            continuation.yield(.setErrorMessage(error.localizedDescription))
                        }
                        continuation.yield(.setLoading(false))
                        continuation.finish()
                    }
                }
            )

        case .popupTapped(let id):
            coordinator.showPopupDetail(id: id)
            return .just(.setErrorMessage(nil))
        }
    }

    func reduce(state: State, mutation: Mutation) -> State {
        var newState = state

        switch mutation {
        case .setLoading(let isLoading):
            newState.isLoading = isLoading
        case .setItems(let items):
            newState.items = items
        case .setErrorMessage(let message):
            newState.errorMessage = message
        }

        return newState
    }
}
```

### 9A.5 적용 규칙

- 신규 feature는 가능하면 `Action / Mutation / State / Store` 구조로 시작한다.
- 단순 화면이라도 action과 state 경계는 먼저 만든다.
- 네트워크 로딩은 `loading start -> result/error -> loading end` 순서가 보이도록 mutation stream으로 표현한다.
- 여러 비동기 작업의 순서 보장이 중요하면 `concat`을 우선한다.
- 입력 순서보다 완료 순서가 중요할 때만 `merge`를 검토한다.
- `@MainActor`는 feature 전체 기본값으로 두지 않는다.
- `@Published` state를 SwiftUI가 직접 관찰하는 store, UIKit/SwiftUI 타입 접근, coordinator UI 전환처럼 메인 액터가 필요한 경계에만 `@MainActor`를 붙인다.
- DTO 변환, 순수 reducer, formatter, mapper, route value, 테스트 fixture에는 `@MainActor`를 붙이지 않는다.

## 10. PopPang 실제 모듈 제안

### 10.1 App

- `App`
- `AppSession`

### 10.2 Coordinator

- `RootCoordinator`
- `MainTabCoordinator`
- `AuthFlowCoordinator`
- `PresentationStores`
- `NavigationContracts`

### 10.3 Features

- `AuthFeature`
- `OnboardingFeature`
- `HomeFeature`
- `SearchFeature`
- `PopupDetailFeature`
- `MapFeature`
- `CalendarFeature`
- `FavoritesFeature`
- `ProfileFeature`
- `AlertFeature`
- `ReviewFeature`

### 10.4 Domain

- `AuthDomain`
- `UserDomain`
- `PopupDomain`
- `ReviewDomain`
- `MapDomain`
- `FavoriteDomain`
- `NotificationDomain`

### 10.5 Data

- `AuthData`
- `UserData`
- `PopupData`
- `ReviewData`
- `NotificationData`
- `ImageCacheData`

### 10.6 ThirdParty

- `FirebaseSDK`
- `KakaoSDK`
- `GoogleSignInSDK`
- `NMapsSDK`
- `KingfisherSDK`

### 10.7 Core

- `HTTPClient`
- `Persistence`
- `Logging`
- `FileCache`
- `DateProvider`
- `ConcurrencyKit`

### 10.8 DSKit

- `DesignToken`
- `Typography`
- `ButtonKit`
- `TagKit`
- `SheetKit`

### 10.9 Shared

- `Localization`
- `TestSupport`

## 11. 현재 코드 매핑 초안

### 11.1 App 계층

현재:

- `PopPang/Sources/App/PopPangApp.swift`
- `PopPang/Sources/App/Delegate/*`
- `PopPang/Sources/App/RootViewModel.swift`
- `PopPang/Sources/App/RootViewSwitcher.swift`
- `PopPang/Sources/App/DIContainer/*`
- `PopPang/Sources/App/Coordinator/*`

목표:

- `PopPangApp.swift` -> 루트 `App` 모듈
- `RootViewModel.swift` -> 분해 후 `App/AppSession`, `Coordinator/RootCoordinator`
- `RootViewSwitcher.swift` -> `Coordinator/RootCoordinator`
- `Coordinator/*` -> 폐기 또는 `PresentationStores + Navigator` 기반으로 재편
- `DIContainer/*` -> `App/AppCore` 또는 dependency registry

### 11.2 Features 계층

현재 `Presentation` 하위 구조 매핑:

- `Onboarding/*` -> `OnboardingFeature`
- `Login/*` -> `AuthFeature`
- `MainTab/Tabs/Home/*` -> `HomeFeature`, `SearchFeature`, `PopupDetailFeature`, `ReviewFeature`
- `MainTab/Tabs/Map/*` -> `MapFeature`
- `MainTab/Tabs/Calendar/*` -> `CalendarFeature`
- `MainTab/Tabs/Favorite/*` -> `FavoritesFeature`
- `MainTab/Tabs/Profile/*` -> `ProfileFeature`
- `AlertView` 계열 -> `AlertFeature`

### 11.3 Shared / Core 매핑

- `DesignSystem/*` -> `DSKit`
- `Util/Constants/LocalizationKeys.swift` -> `Shared/Localization`
- `Util/Logger/*` -> `Core/Logging`
- `Util/Extensions+/*`

분류 원칙:

- UI 확장: `DSKit`
- 순수 Foundation 확장: `Core/FoundationExtensions`
- 앱 전용 convenience: 필요한 feature 내부로 이동

## 12. 테스트 전략

### 12.1 Domain

- UseCase 단위 테스트를 최우선으로 작성한다.
- 외부 의존성 없이 pure test가 가능해야 한다.

### 12.2 Feature

- ViewModel test
- navigation intent test
- state transition test

### 12.3 Data

- mapper test
- repository contract test
- API client integration test

### 12.4 ThirdParty

- SDK wrapper test
- adapter contract test
- bridge smoke test

### 12.5 Coordinator

- root flow test
- tab flow test
- deep link routing test
- global presentation store test

### 12.6 App

- dependency assembly smoke test

## 13. 점진적 마이그레이션 단계

한 번에 갈아엎지 않는다. 아래 순서를 권장한다.

### Phase 1. Tuist 부트스트랩

1. `Workspace.swift` 추가
2. `ProjectDescriptionHelpers` 추가
3. 기존 앱 타깃을 Tuist에서 생성되도록 옮긴다.
4. 아직 모듈 분리는 최소화하고 generate 가능 상태를 만든다.

완료 기준:

- 현행 앱이 Tuist로 동일하게 빌드된다.

### Phase 2. Core / DSKit / Shared 추출

1. Logging
2. Localization
3. DSKit
4. Foundation/UI extensions

완료 기준:

- 공통 코드가 앱 타깃 밖으로 분리된다.

### 13A. V0 기능 유지 기준 마이그레이션 체크리스트

목표:

- `V0`의 현재 기능을 유지한다.
- 구현 위치만 `App / Coordinator / Features / Domain / Data / Shared/*` 구조로 옮긴다.
- 아래 체크리스트를 위에서부터 순서대로 진행한다.
- `V0`에 실제로 있는 기능을 우선 리팩터링한다.
- `V0`에 없는 새 추상화나 새 저장소는 뒤로 미룬다.

원칙:

- `V0`는 참고만 한다.
- 새 구조의 코드가 먼저다.
- 각 단계마다 `tuist generate`, 앱 빌드, 관련 테스트를 통과시킨다.
- 구조 개선보다 `기능 동일성`을 우선한다.
- "지금 당장 더 좋아 보이는 구조"보다 "기존 기능을 그대로 살리는 이동"을 먼저 한다.
- 기존 기능을 모두 옮긴 뒤에야 새 추상화, 새 helper, 새 인프라를 검토한다.

#### A. App / 전역 부트스트랩

- [x] `V0/App/PopPangApp.swift`의 앱 시작 흐름 반영
- [x] `V0/App/Delegate/AppDelegate.swift`의 SDK 초기화, push 연결점 반영
- [x] `V0/App/Delegate/SceneDelegate.swift`에서 필요한 흐름만 추출
- [x] `V0/App/RootViewModel.swift`의 루트 상태 분해
- [x] `V0/App/RootViewSwitcher.swift`의 루트 화면 전환 분해
- [x] `V0/App/DIContainer/DIContainer.swift` 역할을 `Projects/App` 조립 코드로 이전
- [x] `V0/App/DIContainer/ViewModelFactory.swift` 역할을 feature factory 또는 app assembly로 이전
- [x] 앱 entitlements, team, URL scheme, associated domains 유지 확인
- [x] `tuist generate` 후 앱 시뮬레이터 빌드 통과

#### B. Core

- [x] `V0/Data/Infrastructure/Remote/Network/NetworkProvider.swift` 기반 네트워크 토대 반영
- [x] `V0/Data/Infrastructure/Local/UserDefaultsManager.swift` 기반 로컬 저장 반영
- [x] `V0/Data/Infrastructure/Local/Logger.swift` 기반 콘솔 로거 반영
- [x] `V0/Util/Extensions+/DateFormatter+.swift` 반영
- [x] `V0/Util/Extensions+/String+.swift`의 `shortAddress` 반영
- [x] `V0/Util/Constants/Constants.swift`의 API/image/link 상수 반영
- [x] `V0/Util/Constants/Constants.swift`의 plist 키 읽기 로직 정리
  - [x] `KAKAO_NATIVE_APP_KEY`
  - [x] `NMFClientID`
- [x] `V0/Util/Logger/UILogger.swift` 반영
- [x] `V0/Util/Extensions+/UIApplication+.swift` 반영
- [x] `V0/Util/Logger/FirebaseLogger.swift`는 Firebase static link 전파를 피하기 위해 `Projects/App` 조립 계층에 반영
- [x] `V0/Util/Logger/TTT.swift`는 실험용 파일이라 제외 결정
- [ ] `Core` 테스트 계속 보강

Core 후순위 개선 항목:(일단 보류: v0 기능을 모두 옮기는게 우선)

- [ ] `AppConfig` 도입 여부 결정
- [ ] `DateProvider` 도입 여부 결정
- [ ] `UUIDProvider` 도입 여부 결정
- [ ] `JSONDecoder` / `JSONEncoder` 공통 설정 정리
- [ ] `Keychain` 필요 여부 검토
- [ ] `FileCache` 필요 여부 검토

#### C. DSKit

- [x] `V0/DesignSystem/Color/ColorSystem.swift` 이전
- [x] `V0/DesignSystem/Font/UIFont.swift` 이전
- [x] `V0/DesignSystem/Font/FontStyleModifier.swift` 이전
- [x] `V0/DesignSystem/UIConstants.swift` 이전
- [x] V0 공통 이미지 asset과 Localizable strings를 `DSKit` bundle 리소스로 이전
- [ ] 버튼 계열 컴포넌트 이전
  - [x] `DropDownView`
  - [x] `IconButton`
  - [x] `NextButton`
  - [ ] `RegionButton`
  - [x] `SocialLoginButton`
  - [x] `SortButton`
- [ ] `RegionButton`은 `RegionList` 도메인 타입 이관 후 진행
- [x] 달력/레이아웃/네비게이션/시트/태그/텍스트필드 공용 컴포넌트 이전
- [x] UI 확장 이전
  - [x] `View+`
  - [x] `UIImage+`
  - [x] `UINavigationBar+`
  - [x] `UINavigationController`
  - [x] `UITabBar+`
- [x] `DSKitDemo` 카탈로그 앱 추가
  - 위치: `Projects/Shared/DSKit/Demo`
  - 목적: 디자이너가 현재 이관된 토큰과 공용 UI를 한 화면에서 확인
- [ ] `KFImage+`의 위치를 `DSKit` 또는 feature 내부 중 하나로 결정

#### D. Domain

- [x] `Keyword`
- [x] `Popup`
- [x] `Recommend`
- [x] `RegionList`
- [x] `User`
- [x] repository protocol 분리
  - [x] `AdminRepositoryProtocol`
  - [x] `AppleAuthRepositoryProtocol`
  - [x] `GoogleAuthRepositoryProtocol`
  - [x] `KakaoAuthRepositoryProtocol`
  - [x] `PopupRepositoryProtocol`
  - [x] `UserRepositoryProtocol`
- [x] usecase protocol / implementation 정리
- [ ] `DummyData.swift`의 위치 재검토

#### E. Data

- [x] DTO 이전
  - [x] `KeywordDTO`
  - [x] `PopupDTO`
  - [x] `RecommendDTO`
  - [x] `RegionListDTO`
  - [x] `UserDTO`
- [x] API 이전
  - [x] `AdminAPI`
  - [x] `AppleAuthAPI`
  - [x] `GoogleAuthAPI`
  - [x] `KakaoAuthAPI`
  - [x] `PopupAPI`
  - [x] `UserAPI`
- [x] repository implementation 이전
  - [x] `AdminRepositoryImpl`
  - [x] `AppleAuthRepositoryImpl`
  - [x] `GoogleAuthRepositoryImpl`
  - [x] `KakaoAuthRepositoryImpl`
  - [x] `PopupRepositoryImpl`
  - [x] `UserRepositoryImpl`
- [x] `KakaoShareManager`의 최종 위치 결정
  - 최종: `PopupDetailFeature` 내부 helper. SDK product 링크는 `ThirdParty`, 실제 소스 import는 `KakaoSDKShare` 등 SDK 모듈명 직접 사용
- [x] DTO -> Domain mapper 테스트 작성
- [ ] repository contract 테스트 작성

#### F. Coordinator

- [ ] `V0/App/Coordinator/Base/Coordinator.swift` 분석 후 현재 구조에 맞는 최소 개념만 반영
- [ ] `CoordinatorContainer.swift`의 필요 책임만 재설계
- [x] `RootCoordinator` 구현
- [x] `MainTabCoordinator` 구현
- [x] 인증/메인/온보딩 루트 전환 구현
- [x] deep link 처리 지점 확정
- [ ] 글로벌 sheet/fullScreen/overlay 저장소 필요 여부 판단

#### G. Features

- [x] `OnboardingFeature`
  - [x] `OnboardingStep`
  - [x] `OnboardingView`
- [x] `AuthFeature`
  - [x] `LoginView`
  - [x] `RegisterFlowView`
  - [x] `CategorySettingView`
  - [x] `KeywordSettingView`
  - [x] `NicknameSettingView`
- [x] `HomeFeature`
  - [x] 홈 메인 화면
  - [x] 추천/목록 영역
- [x] `SearchFeature`
  - [x] 검색 입력
  - [x] 최근 검색어
- [x] `PopupDetailFeature`
- [x] `MapFeature`
- [x] `CalendarFeature`
- [x] `FavoritesFeature`
- [x] `ProfileFeature`
- [x] `AlertFeature`
- [ ] 각 feature를 `Action / Mutation / State / Store` 구조로 재작성
- [x] 각 feature의 navigation route를 순수 값으로 재정리

#### H. 기능 동일성 체크

- [x] 온보딩 진입
- [x] 소셜 로그인
  - [x] Apple
  - [x] Google
  - [x] Kakao
- [x] 홈 목록 조회
- [x] 홈 검색
- [x] 팝업 상세 진입
- [x] 지도 진입
- [x] 캘린더 진입
- [x] 찜/알림 관련 화면
- [x] 프로필 진입
- [x] 최근 검색어 유지
- [x] FCM 토큰 저장
- [x] 딥링크 popup id 저장/소비
- [x] 관련 링크 이동
  - [x] 서비스 약관
  - [x] 공지/노션 링크

#### I. 단계별 검증 규칙

- [x] 각 큰 단계마다 `tuist generate`
- [ ] 각 모듈 단위 테스트 우선 실행
- [x] 앱 전체 빌드 실행
- [ ] 필요 feature demo 실행
- [ ] `V0`와 동작 차이 발견 시 먼저 체크리스트에 기록

### Phase 3. Domain 추출

1. `User`, `Popup`, `Review` 등 핵심 엔티티 정리
2. usecase protocol / repository protocol 정리
3. feature에서 직접 구현 타입 참조 제거

완료 기준:

- feature가 domain protocol만 통해 동작한다.

### Phase 4. Data 추출

1. 네트워크 API
2. 캐시/저장소
3. 소셜 로그인 SDK adapter

완료 기준:

- domain protocol 구현체가 platform으로 이동한다.

### Phase 5. Feature 분리

추천 순서:

1. `OnboardingFeature`
2. `AuthFeature`
3. `HomeFeature`
4. `SearchFeature`
5. `PopupDetailFeature`
6. `MapFeature`
7. `CalendarFeature`
8. `FavoritesFeature`
9. `ProfileFeature`

완료 기준:

- 각 feature가 독립 타깃으로 빌드된다.

### Phase 6. Coordinator 교체

1. 거대 generic coordinator 의존 제거
2. feature navigator protocol 도입
3. application routing store 도입
4. route의 binding/closure 제거

완료 기준:

- navigation diff에 의한 불필요한 렌더링 범위가 축소된다.

## 14. 코디네이터 리팩터링 우선순위

가장 먼저 바꿔야 할 지점:

1. `buildView(for:)`를 coordinator에서 분리
2. `SheetRoute`에서 `Binding`과 `closure` 제거
3. `EnvironmentObject Coordinator` 직접 주입 범위 축소
4. `RootViewModel`에서 인증 상태와 라우팅 상태 분리

이 4개만 먼저 정리해도 현재 구조의 재렌더링 부담과 결합도를 꽤 줄일 수 있다.

## 15. 초반 구현 규칙

### 15.1 신규 코드 규칙

- 신규 화면은 가능하면 feature 모듈 전제 구조로 작성한다.
- 구현 타입 대신 protocol에 의존한다.
- DTO를 View까지 올리지 않는다.
- route는 경량 식별 값만 가진다.

### 15.2 금지 규칙

- feature에서 다른 feature view 직접 생성 금지
- route에 `Binding` 저장 금지
- route에 `View` 저장 금지
- 지도 bridge public API에 SDK delegate callback를 무분별하게 직접 노출하지 않기
- domain에서 SDK import 금지
- application에서 feature 내부 state 직접 mutate 금지

## 16. 첫 구현 스프린트 제안

### Sprint A

- Tuist 도입
- App 타깃 이전
- DSKit, Logging, Localization 추출

### Sprint B

- HomeFeature / SearchFeature / PopupDetailFeature 분리
- Home navigator protocol 도입
- 기존 MainCoordinator 축소

### Sprint C

- AuthFeature / OnboardingFeature 분리
- Root flow 재정의
- AppSessionStore 도입

### Sprint D

- MapFeature 리팩터링
- sheet/bottom sheet 전용 presentation store 도입
- `NMapsMap`을 modifier 체이닝 기반 선언형 API로 재구성

## 17. 결론

PopPang의 목표 구조는 단순히 폴더를 나누는 것이 아니라, 다음 두 가지를 동시에 달성해야 한다.

1. `feature 중심 개발 생산성`
2. `navigation/assembly 중심 결합도 축소`

즉, Tuist 전환과 coordinator 개선은 별개 작업이 아니라 하나의 방향으로 묶여야 한다.

최종적으로 기대하는 결과:

- feature별 빌드/테스트 속도 개선
- 화면별 오너십 명확화
- 네비게이션 diff 부담 감소
- 도메인 규칙 재사용성 향상
- 장기 유지보수 비용 감소

이 문서는 이후 실제 모듈 생성, manifest 작성, feature 추출 작업의 기준 명세로 사용한다.
