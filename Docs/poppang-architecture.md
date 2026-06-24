# PopPang Architecture Context

이 문서는 Codex가 PopPang 계획 단계에서 반복적으로 확인해야 하는 기본 구조를 줄이기 위한 기준 문서다.

코드와 이 문서가 충돌하면 현재 코드를 우선한다. 다만 코드 변경으로 이 문서의 구조, 규칙, 흐름이 달라지면 같은 작업 범위 안에서 문서 업데이트 필요 여부를 계획에 포함한다.

## 제품 맥락

PopPang은 팝업스토어 정보를 키워드, 검색, 필터, 달력, 지도, 찜, 상세, 공유, 리뷰 흐름으로 제공하는 iOS 앱이다.

주요 기능:

- 관심 키워드 기반 팝업 알림
- 검색과 필터 기반 팝업 탐색
- 달력 기반 일정 확인
- 지도 기반 주변 팝업 탐색
- 관심 팝업 찜 목록 관리
- 팝업 상세, 외부 링크, 공유, 리뷰 흐름

## 기술 기준

- SwiftUI 기반 iOS 앱
- Tuist 기반 workspace/project 구성
- Micro Feature Architecture
- Compound 기반 Feature 상태 관리를 TCA로 점진 전환 중
- 화면 전환은 TCA tree-based / stack-based navigation 기준
- Moya 기반 네트워크와 async/await wrapper
- Firebase, KakaoSDK, GoogleSignIn, Google Mobile Ads, NMapsMap, Kingfisher, BottomSheet 사용
- iOS deployment target은 현재 `17.0` 기준

## 최상위 구조

```text
Projects
├── App
├── Domain
├── Data
├── Features
│   ├── AdFeature
│   ├── AlertFeature
│   ├── AuthFeature
│   ├── CalendarFeature
│   ├── FavoritesFeature
│   ├── HomeFeature
│   ├── MapFeature
│   ├── OnboardingFeature
│   ├── PopupDetailFeature
│   ├── PopupRequestFeature
│   ├── PopupRequestManagementFeature
│   ├── ProfileFeature
│   ├── ReviewFeature
│   └── SearchFeature
└── Shared
    ├── Core
    ├── DSKit
    └── ThirdParty
```

`V0/`는 기존 단일 타깃 구현과 참고 자료 성격이다. 모듈러 구현의 실제 변경은 기본적으로 `Projects/` 아래에서 판단한다.

장기 목표 구조는 `Docs/tca-navigation-guidelines.md`의 `AppFeature`, `AuthFlowFeature`, `MainTabFeature`, `SharedFeature`, `Shared.Models`, `Shared.Clients`, `Shared.Caches` 방향을 따른다. 현재 `Domain`과 feature target을 즉시 대량 이동하지 않고, navigation ownership과 escaping routing 제거를 먼저 진행한다.

## 모듈 책임

### App

위치: `Projects/App`

역할:

- 최종 `PopPangApp` 앱 타깃
- SDK 초기화
- 앱 bootstrap
- repository/usecase live 조립
- `DIContainer` 등록
- `AppFeature` root store 생성
- TCA root/auth/main navigation 소유
- Info.plist, entitlements, app resources 관리

주요 파일:

- `Projects/App/Sources/PopPangApp.swift`
- `Projects/App/Sources/AppCore/AppBootstrap.swift`
- `Projects/App/Sources/AppCore/AppDependencyRegistry.swift`
- `Projects/App/Sources/AppCore/AppSDKInitializer.swift`
- `Projects/App/Project.swift`

### Navigation

상태:

- `Projects/Coordinator` 모듈 제거 완료
- `RootCoordinator`, `MainTabCoordinator`, feature coordinator 제거 완료
- active navigation owner는 `Projects/App/Sources/AppCore/Navigation`의 TCA feature다.

핵심 원칙:

- root flow는 `AppFeature`가 소유한다.
- 전역 현재 유저 상태의 source of truth는 `AppFeature.currentUser`다.
- active main flow는 `MainTabFeature`가 TCA `StackState`와 단일 `@Presents` destination으로 소유한다.
- `MainTabFeature`는 parent가 보유한 `currentUser`와 `mainTabCore`를 projection해서 동작한다.
- `MainTabFeature.Action`은 탭 child action, `path`, `destination`, parent delegate 중심으로 유지한다.
- 탭 내부의 로컬 sheet/bottom sheet/selected item 상태는 각 feature가 소유한다.
- 여러 탭에서 공통으로 여는 push/presentation 화면은 `MainTabFeature`가 소유한다.
- path/destination state에는 navigation intent와 child state만 담고 `Binding`, `View`, 무거운 closure를 넣지 않는다.

### Features

위치: `Projects/Features/*Feature`

역할:

- 사용자 화면과 화면별 state/action/effect 구현
- 기존 Compound 기반 `*FeatureCompound`
- 신규/전환 대상 TCA `@Reducer`
- SwiftUI `*FeatureView`
- reducer action과 delegate action을 통해 상위 flow에 navigation intent 전달

기본 의존:

- `Domain`
- `Core`
- `DSKit`
- `ThirdParty`

주의:

- feature가 다른 feature를 직접 import하는 구조는 기본 전략이 아니다.
- active main flow에서 feature 간 이동은 `MainTabFeature.Path` 또는 `MainTabFeature.Destination` state로 조립한다.
- 화면 로컬 상태는 feature compound 또는 feature view local state에 둔다.
- 전역 이동, 탭 바깥 push, full screen 전환은 상위 TCA parent reducer로 올린다.
- 새 화면 전환용 `@escaping` closure를 추가하지 않는다.

### Domain

위치: `Projects/Domain`

역할:

- Entity
- Repository protocol
- Usecase protocol
- Usecase implementation
- DI container와 `@Dependency`

특징:

- 외부 모듈 의존이 없는 계약 경계다.
- DTO, Moya, SDK 타입을 Domain에 들이지 않는다.
- public protocol 변경은 Feature, Data, App DI 조립에 영향을 준다.

주요 파일:

- `Projects/Domain/Sources/Entities/**`
- `Projects/Domain/Sources/RepositoryProtocol/**`
- `Projects/Domain/Sources/Usecase/Protocols/**`
- `Projects/Domain/Sources/Usecase/Implementations/**`
- `Projects/Domain/Sources/Dependency/DIContainer.swift`

### Data

위치: `Projects/Data`

역할:

- Repository protocol 구현
- Moya API target
- DTO
- DTO와 Domain entity mapping
- 소셜 로그인 SDK 연동 구현

기본 흐름:

```text
Feature
 -> Domain UsecaseProtocol
 -> Domain UsecaseImpl
 -> Domain RepositoryProtocol
 -> Data RepositoryImpl
 -> Data Remote API / SDK
 -> DTO
 -> Domain Entity
```

주의:

- API 계약이나 DTO 변경은 RepositoryImpl, Mapping, Domain entity/usecase 영향을 같이 본다.
- 네트워크 공통 동작은 `Projects/Shared/Core/Sources/Network`를 먼저 확인한다.
- response decoding은 `MoyaProvider+Async.swift`의 async wrapper 기준으로 확인한다.

### Shared/Core

위치: `Projects/Shared/Core`

역할:

- Network 공통 타입
- Moya async wrapper
- local storage
- logging/support/foundation extension

주요 파일:

- `Projects/Shared/Core/Sources/Network/BaseAPI.swift`
- `Projects/Shared/Core/Sources/Network/NetworkProvider.swift`
- `Projects/Shared/Core/Sources/Network/MoyaProvider+Async.swift`

### Shared/DSKit

위치: `Projects/Shared/DSKit`

역할:

- Design system
- 공통 UI component
- font/color/resource
- SwiftUI/UIKit extension

주의:

- feature 전용 UI를 무조건 DSKit으로 올리지 않는다.
- 2개 이상의 feature에서 공유되거나 디자인 시스템 성격이 명확할 때 DSKit 변경을 검토한다.

### Shared/ThirdParty

위치: `Projects/Shared/ThirdParty`

역할:

- 외부 SDK product link hub

원칙:

- 외부 SDK `.external(...)` 선언은 `Projects/Shared/ThirdParty/Project.swift`에 모은다.
- 다른 모듈은 `ThirdParty` target에 의존하되 source에서는 실제 SDK module을 직접 import한다.
- `ThirdParty`는 `@_exported import`로 SDK를 재노출하지 않는다.
- 다만 AdMob 관련 런타임 구현은 `Projects/Shared/ADKit`이 직접 `GoogleMobileAds`를 링크하고 초기화한다.
- SDK product type 정책은 `Tuist/Package.swift`와 `Docs/static-dynamic-linking.md`를 먼저 확인한다.

## 의존성 방향

대표 방향:

```text
App
 -> Features
 -> Domain
 -> Data
 -> Shared

Legacy only:
App
 -> Coordinator
 -> Features
 -> Domain

App
 -> Data
 -> Domain

Features
 -> Core / DSKit / ThirdParty

Data
 -> Core / ThirdParty

DSKit
 -> Core / ThirdParty

Core
 -> ThirdParty

Domain
 -> no project dependency
```

금지 또는 주의:

- `Domain -> Data`, `Domain -> Feature`, `Domain -> Coordinator` 방향 의존을 만들지 않는다.
- feature 간 직접 의존은 기본 전략이 아니다.
- `App -> Coordinator` 의존은 제거된 구조다. 새 Coordinator 의존성을 추가하지 않는다.
- public protocol, DI, module dependency 변경은 작은 수정처럼 보이더라도 영향 범위를 넓게 본다.
- Tuist 설정 변경은 빌드/link/runtime 위험을 함께 검토한다.

## DI 기준

현재 DI는 `Domain`의 `DIContainer`와 `@Dependency`를 사용한다.

흐름:

```text
AppDependencyRegistry.live()
 -> RepositoryImpl 생성
 -> UsecaseImpl 생성
 -> DIContainer.shared.register(..., for: Protocol.self)
 -> FeatureCompound에서 @Dependency로 resolve
```

DI 변경 시 함께 확인할 파일:

- `Projects/App/Sources/AppCore/AppDependencyRegistry.swift`
- `Projects/Domain/Sources/Dependency/DIContainer.swift`
- `Projects/Domain/Sources/Usecase/Protocols/**`
- `Projects/Domain/Sources/Usecase/Implementations/**`
- `Projects/Domain/Sources/RepositoryProtocol/**`
- 관련 Feature의 `*FeatureCompound.swift`
- 관련 Demo app의 mock registration

## Navigation 기준

자세한 기준은 `Docs/tca-navigation-guidelines.md`를 우선한다.

계획 단계 체크:

- 앱 루트 전환인지, MainTab 전역 이동인지, feature 로컬 상태인지 구분한다.
- root/auth/sheet/fullScreen처럼 동시에 하나만 떠야 하는 화면은 tree-based navigation을 사용한다.
- tree-based navigation에서 여러 destination이 있으면 `@Reducer enum Destination`을 만들고 State에는 `@Presents var destination: Destination.State?` 하나만 둔다.
- push가 누적되는 drill-down 화면은 stack-based navigation을 사용한다.
- MainTab 전역 push 이동이면 `MainTabFeature.Path` 영향 여부를 확인한다.
- MainTab presentation 이동이면 `MainTabFeature.Destination` 영향 여부를 확인한다.
- active main flow feature는 delegate action을 통해 `MainTabFeature`로 navigation intent를 전달한다.
- path/destination state에는 runtime state, `Binding`, `View`, 무거운 closure를 넣지 않는다.
- Map bottom sheet처럼 feature 내부 interaction 상태는 feature가 소유한다.
- 화면 전환용 escaping closure는 제거 대상이며 새로 추가하지 않는다.

## 네트워크와 API 기준

기본 위치:

- API target: `Projects/Data/Sources/Remote/**`
- Repository 구현: `Projects/Data/Sources/RepositoryImpl/**`
- DTO: `Projects/Data/Sources/DTO/**`
- Mapping: `Projects/Data/Sources/Mapping/**`
- 공통 네트워크: `Projects/Shared/Core/Sources/Network/**`

변경 영향:

- endpoint 추가/수정은 API target, DTO, mapping, repository protocol, repository impl, usecase, feature 호출부를 함께 본다.
- 서버 계약 변경은 API/DTO/public protocol 변경에 해당하므로 계획에서 명시한다.
- `BaseAPI`, `NetworkProvider`, `MoyaProvider+Async` 변경은 전체 네트워크 호출에 영향이 있다.

## Tuist와 링크 기준

참고 문서:

- `Docs/static-dynamic-linking.md`
- `Docs/Troubleshotting.md`

원칙:

- feature target은 기본적으로 `.staticFramework` 성격의 앱 내부 leaf feature로 본다.
- `Coordinator`는 legacy 공유 경계이며 제거 대상이다.
- `Domain`, `Data`, `Core`, `DSKit`, `ThirdParty`는 현재 공유 경계로 본다.
- 장기적으로 `Shared.Models`, `Shared.Clients`, `Shared.Caches`, `SharedFeature` 분리를 검토한다.
- 외부 SDK 링크 문제는 `ThirdParty`와 `Tuist/Package.swift` product type 정책을 같이 확인한다.
- `tuist generate`, `make regen`, `make clean`, `make reinstall`은 파일을 생성/삭제/갱신할 수 있으므로 승인 없이 실행하지 않는다.
- `Projects/**/Derived`, `*.xcodeproj`, `PopPang.xcworkspace`는 생성물 성격이므로 계획 없이 직접 수정하지 않는다.

## 문서 동기화 규칙

코드 변경 계획이나 구현이 아래를 바꾸면 문서 업데이트 필요 여부를 반드시 검토한다.

- 모듈 책임이나 의존성 방향
- TCA navigation 규칙
- DI 조립 방식
- API/DTO/entity/usecase 흐름
- ThirdParty 링크 정책
- Tuist product type 또는 package 정책
- 공통 네트워크, logging, storage, design system 규칙
- 기존 문서에 적힌 트러블슈팅의 원인이나 해결책

문서 업데이트 후보:

- `Docs/tca-navigation-guidelines.md`
- `Docs/poppang-architecture.md`
- `Docs/static-dynamic-linking.md`
- `Docs/Troubleshotting.md`
- `Docs/logger.md`
- 기능별 새 문서가 이미 있으면 해당 문서

문서와 코드가 어긋나는데 이번 작업 범위에서 문서 수정까지 할 수 없다면, 계획 또는 최종 응답에 문서 후속 작업으로 명시한다.

## Planning Pipeline 사용 시 우선 확인

계획 요청을 받으면 먼저 이 문서를 읽고, 그 다음 요청과 직접 관련된 실제 파일을 `rg`/`sed -n`으로 확인한다.

공통 구조를 이 문서만으로 단정하지 말고, 변경 대상 파일의 현재 구현을 확인한다.

요청별 기본 탐색 예:

- 앱 시작, SDK, DI: `Projects/App/Sources/AppCore/**`
- 루트 전환, 탭, 화면 이동: `Docs/tca-navigation-guidelines.md`, `Projects/App/Sources/AppCore/Navigation/**`
- 화면 상태/UI: `Projects/Features/<FeatureName>/Sources/**`
- 도메인 계약: `Projects/Domain/Sources/**`
- API/DTO/repository: `Projects/Data/Sources/**`
- 네트워크 공통: `Projects/Shared/Core/Sources/Network/**`
- 디자인 시스템: `Projects/Shared/DSKit/Sources/**`
- 링크/패키지: `Projects/Shared/ThirdParty/Project.swift`, `Tuist/Package.swift`

## 변경 전 주의 대상

아래는 계획에서 영향 여부를 명시해야 한다.

- API 계약
- DB schema
- DTO
- Domain entity
- public protocol
- DI registration
- TCA route/path/destination
- module dependency
- Tuist package/product type
- Info.plist, entitlements, signing 설정
- secret/config 파일

아래 파일은 열람하거나 출력하지 않는다.

- `.env`
- `*.xcconfig`
- `GoogleService-Info.plist`
- 인증키, 토큰, 비밀번호가 담긴 파일
