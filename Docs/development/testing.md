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
| SheetKit 테스트 | `xcodebuild test -workspace PopPang.xcworkspace -scheme SheetKit -destination 'id=<시뮬레이터 UDID>'` | 2026-10-14 로컬에서 실행해 24개 통과. CI는 `3. poppang-build-and-test.yml`의 `sheetkit-test` job |
| feature 테스트 실행 | `xcodebuild test -workspace PopPang.xcworkspace -scheme HomeFeatureV2 -destination 'id=<시뮬레이터 UDID>' -only-testing:HomeFeatureV2Tests` (MainTab은 `-scheme MainTabFeature -only-testing:MainTabFeatureTests`, 찜은 `-scheme FavoritesFeature -only-testing:FavoritesFeatureTests`, 팝업 상세는 `-scheme PopupDetailFeature -only-testing:PopupDetailFeatureTests`, 인증은 `-scheme AuthFeatureV2 -only-testing:AuthFeatureV2Tests`, 온보딩은 `-scheme OnboardingFeatureV2 -only-testing:OnboardingFeatureV2Tests`) | PR #92 검증 명령. scheme은 Tuist가 모듈 이름으로 자동 생성한다. |
| 시뮬레이터·환경 | CI는 macOS 15 + Xcode 26.2에서 사용 가능한 첫 번째 iPhone 시뮬레이터를 쓴다. | CI workflow |

테스트를 실행하려면 workspace가 있어야 한다. 처음이라면 [Tuist 설치와 실행](tuist.md)의 순서를 먼저 따른다. `tuist test`는 workspace를 다시 만들 수 있으므로 에이전트는 승인을 받고 실행한다.

## 테스트 타깃

| 모듈 | 타깃 | 파일 수 | `@Test` 수 | 내용 |
| --- | --- | --- | --- | --- |
| Core | `CoreTests` | 9 | 51 | 네트워크(Moya stub), V2 인증 헤더·토큰 갱신·재요청, 로컬 저장소. `KeychainStore` 테스트 1개는 entitlement가 없는 테스트 환경이라 건너뛴다. |
| SheetKit | `SheetKitTests` | 4 | 33 | 하단 시트 높이 계산, 최대 높이로 그린 시트를 내리는 거리와 가려지는 아래쪽 높이, 부동소수점 오차만큼의 높이 변화 무시, 손을 뗀 높이와 속도로 고르는 멈출 높이, 짧게 튕겨도 한 단계 가기, 나타나고 숨을 때 움직일 거리, 손잡이 탭·VoiceOver 조절, 겹친 시트 가운데 더 높이 올라온 시트의 높이 고르기, 겹친 시트가 끄는 거리의 합, 끌기를 받을 곳 판단 |
| Data | `DataTests` | 8 | 99 | DTO 변환, 계약, 서버 헬스 체크 판정(`URLProtocol` stub), V2 인증 요청 형식·로그인·가입·세션 복구(가짜 소셜 로그인 전략과 Moya stub), 가입 화면 닉네임 추천·인기 키워드 요청 형식과 응답(빈 배열 포함), V2 내 정보 요청 형식·응답·실패 코드·탈퇴 재요청, 가입 OS 채우기 마이그레이션 실행·기록, 회원 팝업 V2 검색과 팝업 응답의 null 필드, V2 찜 목록·등록·해제 요청 형식과 실패 변환, V2 팝업 상세 단건 조회·조회 기록·관련 팝업 요청 형식과 응답·없는 팝업(404 4301) 변환, V2 관리자 팝업 비활성화 요청 형식과 실패 변환 |
| HomeFeatureV2 | `HomeFeatureV2Tests` (`Tests/HomeFeatureTests.swift`) | 1 | 8 | TCA `TestStore`, 광고 배치 정책 |
| MainTabFeature | `MainTabFeatureTests` | 1 | 7 | delegate → path·destination 전환, 해제 순서, 팝업 상세를 `popupUuid`만으로 열기 |
| PopupDetailFeature | `PopupDetailFeatureTests` | 1 | 7 | TCA `TestStore`, `popupUuid`로 상세 받기(로딩 → 내용), 없는 팝업·실패 화면과 다시 시도, 관련 팝업·조회 기록 실패에도 내용 표시, 하트 실패 되돌리기, 불러오기 전 하트·비활성화 막기, 관리자 비활성화 |
| FavoritesFeature | `FavoritesFeatureTests` | 1 | 9 | TCA `TestStore`, 찜 해제를 먼저 숨기기, 해제 중에 온 목록 응답, 연달아 해제 중 실패, 실패·로그인 끊김 때 되돌리기, 같은 하트 반복 탭, 찜하지 않은 팝업 무시, 목록 실패 문구와 다시 받은 뒤 지우기 |
| AuthFeature | `AuthFeatureTests` | 1 | 9 | 앱이 더 쓰지 않는 기존 모듈. 로그인 결과(COMPLETED/PENDING) 분기, 실패 안내, 가입 완료·만료·닉네임 중복, 가입 화면 닉네임 확인·카테고리 목록 실패 |
| AuthFeatureV2 | `AuthFeatureV2Tests` | 1 | 37 | TCA `TestStore`, AuthFeature 테스트를 옮긴 것에 더해 추천 닉네임 채우기·다시 추천·실패, 카테고리 선택과 건너뛰기 막기, 인기 키워드 받기·탭 추가·5개 제한, 가입 성공 뒤 완료 화면과 시작하기, 카테고리 다시 받기, 늦게 온 닉네임 확인 결과 버리기, 확인 때 추천 취소, 추천 중 다음 막기, 건너뛰면 키워드 없이 가입(실패하면 키워드 유지), 빈 카테고리 목록 다시 시도, 뒤로 가면 실패 문구 지우기, 확인 두 번 누름 막기, 인기 키워드 중복 제거, 가입 중 뒤로 가기 막기, 규칙에 어긋난 추천 닉네임 거르기 |
| OnboardingFeatureV2 | `OnboardingFeatureV2Tests` | 1 | 6 | TCA `TestStore`, 다음·건너뛰기·넘기기로 화면 이동과 로그인 요청, 화면마다 쓰는 카드·아이콘·화살표가 DSKit 에셋에 있는지 |

App, Domain, DSKit, 다른 feature에는 테스트 타깃이 없다.

## CI가 검증하는 범위

| workflow | 실행 시점 | 하는 일 |
| --- | --- | --- |
| `3. poppang-build-and-test.yml` | `main` 대상 PR(opened, synchronize, reopened, ready_for_review), 매일 22:00 UTC, 수동 | `PopPangApp`(`Domain` 포함)·`DSKit` 빌드, `Core`·`Data`·`SheetKit` 테스트 |
| `2. poppang-test.yml` | 수동, PR 댓글 `/팝팡 테스트` | `Core`·`Data` 테스트 |
| `1. poppang-build.yml` | 수동, PR 댓글 `/팝팡 빌드` | `PopPangApp` clean build |
| `0. poppang-dependency-canary.yml` | 매주 월요일 03:00 UTC, PR 댓글 `/팝팡 버전점검` | `Package.resolved`를 지우고 최신 해석으로 `PopPangApp` 빌드 |

PR 댓글 `/팝팡 빌드하고테스트`는 3번 workflow를 실행한다.

3번 workflow는 시뮬레이터용 arm64만 빌드한다(`ARCHS=arm64`). CI 러너가 Apple Silicon이라 x86_64 시뮬레이터 빌드는 확인하지 않는다. `Domain`은 `PopPangApp`을 빌드할 때 함께 빌드되어 따로 job을 두지 않는다.

**feature 테스트(`HomeFeatureV2Tests`, `MainTabFeatureTests` 등)는 CI에서 실행되지 않는다.** reducer나 navigation을 바꿨다면 로컬에서 해당 테스트를 실행하고 결과를 PR에 적는다.

## 변경별로 확인할 테스트

| 바꾼 것 | 확인할 것 |
| --- | --- |
| reducer 상태·effect | 해당 feature의 `TestStore` 테스트. 없으면 추가를 검토한다. |
| delegate, path, destination | `MainTabFeatureTests`처럼 parent reducer에서 child delegate를 보냈을 때 path·destination이 바뀌는지 |
| DTO, Mapping, API | `DataTests` |
| 네트워크 공통, 로컬 저장소 | `CoreTests` |
| 목록 UI(PopPangListKit) | reducer 테스트 + Demo 앱에서 화면 확인. 목록 자체의 unit test는 없다. |
| 하단 시트(SheetKit) | `SheetKitTests` + `SheetKitDemo`와 DSKit 데모의 지도 탭에서 두 탭바 모양으로 화면 확인 |
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
