# PopPang 테스트

이 문서는 PopPang의 테스트 타깃, 실행 명령, CI 검증 범위, 테스트 작성 방식을 정리한다.

실행 명령에는 근거를 함께 적는다. 이 문서를 작성하면서 명령을 직접 실행하지는 않았다. 로컬에서 실행해 결과를 확인한 명령은 `근거` 칸을 갱신한다.

## 테스트 대상과 실행 방법

| 항목 | 값 | 근거 |
| --- | --- | --- |
| 테스트 프레임워크 | Swift Testing(`import Testing`, `@Test`, `#expect`). XCTest는 쓰지 않는다. | 모든 테스트 파일 |
| 로컬 실행(Core, Data) | `tuist test Core`, `tuist test Data` | `README.md` 5장 |
| CI 실행(Core, Data) | `xcodebuild test -workspace PopPang.xcworkspace -scheme Core`(또는 `Data`) `-destination 'platform=iOS Simulator,id=<첫 번째 iPhone 시뮬레이터>'` | `.github/workflows/2. poppang-test.yml`, `3. poppang-build-and-test.yml` |
| fastlane | `bundle exec fastlane test` (Core → Data, iPhone 16, 코드 커버리지) | `fastlane/Fastfile` |
| feature 테스트 실행 | `xcodebuild test -workspace PopPang.xcworkspace -scheme HomeFeatureV2 -destination 'id=<시뮬레이터 UDID>' -only-testing:HomeFeatureV2Tests` (MainTab은 `-scheme MainTabFeature -only-testing:MainTabFeatureTests`) | PR #92 검증 명령. scheme은 Tuist가 모듈 이름으로 자동 생성한다. |
| 시뮬레이터·환경 | CI는 macOS 15 + Xcode 26.2에서 사용 가능한 첫 번째 iPhone 시뮬레이터를 쓴다. | CI workflow |

테스트를 실행하려면 workspace가 있어야 한다. 처음이라면 [Tuist 설치와 실행](tuist.md)의 순서를 먼저 따른다. `tuist test`는 workspace를 다시 만들 수 있으므로 에이전트는 승인을 받고 실행한다.

## 테스트 타깃

| 모듈 | 타깃 | 파일 수 | `@Test` 수 | 내용 |
| --- | --- | --- | --- | --- |
| Core | `CoreTests` | 7 | 15 | 네트워크(Moya stub), 로컬 저장소 |
| Data | `DataTests` | 2 | 23 | DTO 변환, 계약, 서버 헬스 체크 판정(`URLProtocol` stub) |
| HomeFeatureV2 | `HomeFeatureV2Tests` (`Tests/HomeFeatureTests.swift`) | 1 | 8 | TCA `TestStore`, 광고 배치 정책 |
| MainTabFeature | `MainTabFeatureTests` | 1 | 6 | delegate → path·destination 전환, 해제 순서 |

App, Domain, DSKit, 다른 feature에는 테스트 타깃이 없다.

## CI가 검증하는 범위

| workflow | 실행 시점 | 하는 일 |
| --- | --- | --- |
| `3. poppang-build-and-test.yml` | `main` 대상 PR(opened, synchronize, reopened, ready_for_review), 매일 22:00 UTC, 수동 | `PopPangApp`·`Domain`·`DSKit` 빌드, `Core`·`Data` 테스트 |
| `2. poppang-test.yml` | 수동, PR 댓글 `/팝팡 테스트` | `Core`·`Data` 테스트 |
| `1. poppang-build.yml` | 수동, PR 댓글 `/팝팡 빌드` | `PopPangApp` clean build |
| `0. poppang-dependency-canary.yml` | 매주 월요일 03:00 UTC, PR 댓글 `/팝팡 버전점검` | `Package.resolved`를 지우고 최신 해석으로 `PopPangApp` 빌드 |

PR 댓글 `/팝팡 빌드하고테스트`는 3번 workflow를 실행한다.

3번 workflow는 시뮬레이터용 arm64만 빌드한다(`ARCHS=arm64`). CI 러너가 Apple Silicon이라 x86_64 시뮬레이터 빌드는 확인하지 않는다.

**feature 테스트(`HomeFeatureV2Tests`, `MainTabFeatureTests` 등)는 CI에서 실행되지 않는다.** reducer나 navigation을 바꿨다면 로컬에서 해당 테스트를 실행하고 결과를 PR에 적는다.

## 변경별로 확인할 테스트

| 바꾼 것 | 확인할 것 |
| --- | --- |
| reducer 상태·effect | 해당 feature의 `TestStore` 테스트. 없으면 추가를 검토한다. |
| delegate, path, destination | `MainTabFeatureTests`처럼 parent reducer에서 child delegate를 보냈을 때 path·destination이 바뀌는지 |
| DTO, Mapping, API | `DataTests` |
| 네트워크 공통, 로컬 저장소 | `CoreTests` |
| 목록 UI(PopPangListKit) | reducer 테스트 + Demo 앱에서 화면 확인. 목록 자체의 unit test는 없다. |
| 모듈·Tuist 설정 | `PopPangApp` 빌드 |

## TCA 테스트 작성 방식

테스트 타입은 `@MainActor struct`로 만들고, 테스트 이름은 `@Test("한국어 설명")`으로 적는다.

```swift
import ComposableArchitecture
import Domain
import Testing
@testable import HomeFeatureV2

@MainActor
struct HomeFeatureTests {
    @Test("HomeFeature가 닉네임 갱신 action을 상태에 반영한다")
    func homeFeatureUpdatesNickname() async {
        let store = TestStore(initialState: HomeFeature.State(user: makeUser())) {
            HomeFeature()
        }
        ...
    }
}
```

의존성은 `withDependencies`에서 필요한 closure만 바꾸고, closure 안에서 전달된 값도 검증한다.

```swift
let store = TestStore(initialState: HomeFeature.State(user: user)) {
    HomeFeature()
} withDependencies: {
    $0.homePopupClient.getPersonalRandomPopupList = { userUuid in
        #expect(userUuid == "user-1")
        return bestPopups
    }
}

await store.send(.onAppear) {
    $0.isLoading = true
    $0.errorMessage = nil
}
await store.receive(.popupSectionsLoaded(...)) {
    $0.bestPopups = bestPopups
}
await store.receive(.loadingChanged(false)) {
    $0.isLoading = false
}
```

parent navigation처럼 일부 상태만 확인하면 되는 테스트는 `exhaustivity`를 끈다.

```swift
let store = TestStore(initialState: MainTabFeature.State(session: makeSession())) {
    MainTabFeature()
}
store.exhaustivity = .off

await store.send(.home(.delegate(.searchTapped)))

guard case let .search(searchState)? = store.state.core.destination else {
    Issue.record("search destination should be presented")
    return
}
#expect(searchState.search.userUuid == "user-1")
```

- Action이 `Equatable`이 아니면 `store.receive(\.searchDismissTeardownCompleted)`처럼 case key path로 받는다.
- `@Shared` 상태는 `Shared(value:)`로 만든다.
- 해제 순서가 있는 전환(`Task.yield()` 뒤 후속 action)은 후속 action까지 `receive`로 확인한다.

## 기타 테스트 패턴

| 대상 | 방법 | 예 |
| --- | --- | --- |
| 네트워크 | `MoyaProvider.immediatelyStub`과 `await #expect(throws:)` | `Projects/Shared/Core/Tests/Network/NetworkTests.swift` |
| 로컬 저장소 | 테스트마다 `UserDefaults(suiteName:)`로 분리 | `Projects/Shared/Core/Tests/**/LocalStorageTests.swift` |
| client 기본값 | `testValue`가 빈 응답을 돌려주거나 `unimplemented`로 실패한다. 테스트에서 쓰는 closure는 직접 바꾼다. | `HomePopupClient`, `ProfileFeatureClient` |

## 결과 기록

- 실행한 테스트와 결과를 PR의 체크리스트나 추가 설명에 적는다.
- 자동 테스트로 확인하기 어려운 화면 동작은 재현 단계와 확인 결과를 적는다.
- 실행하지 못한 테스트는 통과했다고 적지 않는다. 이유와 남은 검증을 적는다.

## 관련 문서

- [Tuist 설치와 실행](tuist.md)
- [TCA Feature 작성 규칙](../architecture/tca-feature.md)
- [TCA Navigation](../architecture/tca-navigation.md)
- [Git 작업 흐름](gitflow.md)
