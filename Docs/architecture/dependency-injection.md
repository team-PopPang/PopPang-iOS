# PopPang 의존성 주입

이 문서는 Repository와 Usecase를 조립하고, TCA reducer가 쓰는 feature-scoped client를 만들어 주입하는 기준이다. 새 client를 만들거나 조립 방식을 바꾸기 전에 읽는다.

## 목차

- [전체 흐름](#전체-흐름)
- [Composition root](#composition-root)
- [Feature-scoped client](#feature-scoped-client)
- [새 client 추가 순서](#새-client-추가-순서)
- [세션과 로컬 저장소](#세션과-로컬-저장소)
- [Demo와 테스트에서 주입하기](#demo와-테스트에서-주입하기)
- [하지 않는 것](#하지-않는-것)

## 전체 흐름

```text
PopPangApp.init
→ AppBootstrap.live()
   ├─ AppDependencyRegistry.live()
   │   ├─ AppRepositoryRegistry.live()   RepositoryImpl 생성 (Data)
   │   └─ AppUsecaseRegistry             UsecaseImpl 생성 (Domain)
   ├─ LocalSessionClient.live(...)
   ├─ MainTabFeatureDependencies(...)    탭·상세 feature client의 .live(...) 조립
   └─ AppNotificationManager.shared.configure(...)
→ AppBootstrap.makeAppStore()
   └─ Store(initialState:) { AppFeature(...) } withDependencies: { ... }
      ├─ ServerHealthClient.live(...)    앱 시작 헬스 체크
      └─ AuthFeatureClient.live(...)     로그인
→ 모든 하위 reducer가 @Dependency로 client를 읽음
```

reducer는 `DependencyValues`로만 의존성을 받는다. 실제 구현은 composition root에서 만들어 `withDependencies`로 넣는다.

## Composition root

| 파일 | 하는 일 |
| --- | --- |
| `Projects/App/Sources/AppCore/1. AppDependencyRegistry.swift` | `AppRepositoryRegistry`가 `PopupRepositoryImpl()` 같은 Repository를, `AppUsecaseRegistry`가 `PopupUsecaseImpl(popupRepository:)` 같은 Usecase를 만든다. |
| `Projects/App/Sources/AppCore/2. AppBootstrap.swift` | 같은 `KeyValueStoring` 저장소와 Usecase 인스턴스를 여러 객체에 나눠 주고, `makeAppStore()`에서 `withDependencies`로 주입한다. |
| `Projects/Features/MainTabFeature/Sources/MainTabFeatureDependencies.swift` | 탭과 상세 feature client(`alertFeatureClient`, `calendarFeatureClient`, `homePopupClient` 등)의 `.live(...)`를 만들고 `configure(_:)`로 `DependencyValues`에 넣는다. |

`makeAppStore()`의 주입 코드:

```swift
Store(initialState: AppFeature.State()) {
    AppFeature(
        sessionStorage: sessionStorage,
        launchStateResolver: launchStateResolver
    )
} withDependencies: {
    $0.localSessionClient = localSessionClient
    $0.serverHealthClient = .live(
        serverHealthUsecase: dependencies.usecases.serverHealthUsecase
    )
    mainTabFeatureDependencies.configure(&$0)
    $0.authFeatureClient = .live(
        kakaoAuthUsecase: dependencies.usecases.kakaoAuthUsecase,
        googleAuthUsecase: dependencies.usecases.googleAuthUsecase,
        appleAuthUsecase: dependencies.usecases.appleAuthUsecase,
        userUsecase: dependencies.usecases.userUsecase
    )
}
```

- 로그인 이후 탭·상세 feature의 client는 `MainTabFeatureDependencies`에서 조립한다.
- 앱 루트·인증 단계의 client는 `AppBootstrap.makeAppStore()`에서 조립한다.
- `AppFeature`는 `LocalSessionStorage`와 `AppLaunchStateResolver`를 `init`으로 받는다. 동기적으로 쓰는 값이라 dependency 대신 생성자 주입을 쓴다.

## Feature-scoped client

feature마다 필요한 작업만 모은 client를 `Sources/Dependency/<Name>Client.swift`에 둔다. Usecase protocol 전체를 reducer에 넘기지 않는다.

### 구조

`CalendarFeatureClient`가 기준 예시다.

```swift
import ComposableArchitecture
import Domain

public struct CalendarFeatureClient: Sendable {
    public var getRegionList: @Sendable () async throws -> [RegionList]
    public var addFavorite: @Sendable (_ userUuid: String, _ popupUuid: String) async throws -> Void

    public init(
        getRegionList: @escaping @Sendable () async throws -> [RegionList],
        addFavorite: @escaping @Sendable (_ userUuid: String, _ popupUuid: String) async throws -> Void
    ) {
        self.getRegionList = getRegionList
        self.addFavorite = addFavorite
    }

    public static func live(
        popupUsecase: PopupUsecaseProtocol
    ) -> Self {
        let popupUsecaseBox = PopupUsecaseBox(popupUsecase)

        return Self(
            getRegionList: {
                try await popupUsecaseBox.usecase.getRegionList()
            },
            addFavorite: { userUuid, popupUuid in
                try await popupUsecaseBox.usecase.addFavorite(userUuid: userUuid, popupUuid: popupUuid)
            }
        )
    }
}

extension CalendarFeatureClient: DependencyKey {
    public static let liveValue = Self(
        getRegionList: { [] },
        addFavorite: { _, _ in }
    )
}

extension CalendarFeatureClient: TestDependencyKey {
    public static let testValue = Self(
        getRegionList: { [] },
        addFavorite: { _, _ in }
    )
}

extension DependencyValues {
    public var calendarFeatureClient: CalendarFeatureClient {
        get { self[CalendarFeatureClient.self] }
        set { self[CalendarFeatureClient.self] = newValue }
    }
}

private final class PopupUsecaseBox: @unchecked Sendable {
    let usecase: PopupUsecaseProtocol

    init(_ usecase: PopupUsecaseProtocol) {
        self.usecase = usecase
    }
}
```

### 규칙

| 항목 | 기준 |
| --- | --- |
| 타입 | `public struct <Name>FeatureClient: Sendable`. 이름과 `DependencyValues` key는 `<name>FeatureClient`로 맞춘다. `HomePopupClient`, `PopupDetailClient`는 예외다. |
| 멤버 | `@Sendable` closure 프로퍼티. 파라미터에는 `_ userUuid: String`처럼 이름을 붙인다. |
| 생성자 | `@escaping @Sendable` closure를 받는 `public init`을 직접 쓴다. `@DependencyClient` macro는 쓰지 않는다. |
| 실제 구현 | `public static func live(<usecase>:) -> Self`. Usecase protocol이 `Sendable`이 아니므로 `private final class <Name>UsecaseBox: @unchecked Sendable`로 감싸서 캡처한다. |
| `liveValue` | 주입 전 기본값이다. 빈 응답을 돌려주는 stub(Calendar, Favorites, Map, Search, Home)이나 오류를 던지는 `Self.unimplemented`(Alert, Auth, Profile)를 쓴다. 실제 구현을 넣지 않는다. |
| `testValue` | `TestDependencyKey` extension에 둔다. 테스트는 필요한 closure만 `withDependencies`에서 바꾼다. |
| `previewValue` | 필요하면 `#if DEBUG` 안에 둔다. 현재 `HomePopupClient`만 있다. |

새 client는 `liveValue`와 `testValue`를 `Self.unimplemented`로 두는 쪽을 권장한다. 빈 stub이면 composition root에서 주입을 빠뜨려도 화면이 조용히 비어 보이지만, `unimplemented`는 오류로 바로 드러난다. 기존 client는 바꾸지 않는다.

### reducer에서 쓰기

```swift
@Dependency(\.calendarFeatureClient) private var calendarFeatureClient: CalendarFeatureClient
```

- 프로퍼티 이름은 key 이름과 같게 짓는다.
- effect에서는 `let calendarFeatureClient = calendarFeatureClient`로 꺼내 캡처한다. reducer 전체(`self`)를 캡처하지 않는다.
- 사용법은 [TCA Feature 작성 규칙](tca-feature.md#effect)을 본다.

## 새 client 추가 순서

1. Domain에 필요한 Usecase 메서드가 있는지 확인한다. 없으면 [아키텍처](architecture.md#새-기능-개발-체크리스트) 순서로 추가한다.
2. feature 모듈에 `Sources/Dependency/<Name>FeatureClient.swift`를 만들고 위 구조를 따른다.
3. reducer에서 `@Dependency(\.<name>FeatureClient)`로 쓴다.
4. composition root에 연결한다.
   - 탭·상세 feature: `MainTabFeatureDependencies`에 `private let` 프로퍼티, `init`의 `.live(...)` 조립, `configure(_:)`의 대입을 추가한다.
   - 루트·인증 feature: `AppBootstrap.makeAppStore()`의 `withDependencies`에 추가한다.
5. Demo 앱과 테스트에서 client를 주입한다.
6. 연결을 빠뜨리지 않았는지 앱에서 화면을 열어 확인한다.

## 세션과 로컬 저장소

| 타입 | 위치 | 역할 |
| --- | --- | --- |
| `UserSession` | `Core/Sources/Support/UserSession.swift` | 앱이 지금 쓰는 세션. source of truth는 `AppFeature.State.session`(`@Shared`)이다. |
| `LocalSessionClient` | `App/Sources/AppCore/LocalSessionClient.swift` | 세션 load·save·clear. `LocalSessionStorage`와 `UserUsecaseProtocol`을 조합한다. |
| `LocalSessionStorage` | `Core/Sources/LocalStorage/Session/` | `userID`, 온보딩 완료 여부 같은 로컬 값 읽기·쓰기 |
| `KeyValueStoring` / `UserDefaultsStore` | `Core/Sources/LocalStorage/Support/` | 저장소 추상화. `AppBootstrap.live(store:)`가 하나를 만들어 여러 저장소에 나눠 준다. |
| `RecentSearchStorage`, `PushTokenStorage` | `Core/Sources/LocalStorage/` | 최근 검색어, 푸시 토큰 |

reducer는 UserDefaults나 Keychain에 직접 접근하지 않는다. client나 저장소 타입을 통해 접근한다.

## Demo와 테스트에서 주입하기

Demo 앱은 `Store(initialState:) { Feature() } withDependencies: { ... }`로 client를 직접 넣는다.

| 방식 | 예 | 쓰는 때 |
| --- | --- | --- |
| inline stub | `CalendarFeatureDemoApp`의 `CalendarFeatureClient(getRegionList: { ... }, ...)` | 서버 없이 화면만 확인할 때 |
| `previewValue` | `HomeFeatureDemoApp`의 `$0.homePopupClient = .previewValue` | 미리 만든 샘플 데이터가 있을 때. DEBUG 빌드에서만 쓸 수 있다. |
| 실제 네트워크 | `HomeFeatureV2Demo`의 `HomePopupClient.live(popupUsecase: PopupUsecaseImpl(popupRepository: PopupRepositoryImpl()))` | 실제 API로 확인할 때. Demo 타깃이 `Data`에 의존한다. |

- Demo에 필요한 사용자 UUID 같은 값은 Demo 전용 `.xcconfig`(예: `HOME_DEMO_USER_UUID`)에서 읽는다. xcconfig 파일 내용은 열람하거나 커밋하지 않는다.
- 테스트는 `TestStore(initialState:) { Feature() } withDependencies: { $0.<client>.<closure> = { ... } }`로 필요한 closure만 바꾼다. ([테스트](../development/testing.md))

## 하지 않는 것

- reducer에서 Usecase, Repository, `NetworkProvider`, 싱글턴을 직접 만들거나 호출하지 않는다.
- client의 `liveValue` 안에서 Usecase나 Repository를 만들거나 다른 container에서 꺼내지 않는다. 실제 구현은 composition root에서만 만든다.
- `Projects/Domain/Sources/Dependency/DIContainer.swift`(빈 placeholder)를 다시 쓰지 않는다.
- feature client에 다른 feature의 작업을 섞지 않는다. 필요한 작업만 담는다.

## 관련 문서

- [아키텍처](architecture.md)
- [TCA Feature 작성 규칙](tca-feature.md)
- [테스트](../development/testing.md)
