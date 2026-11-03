import ComposableArchitecture
import Domain
import Foundation
import Testing
@testable import AuthFeatureV2

@MainActor
struct AuthFeatureV2Tests {
    @Test("가입을 마친 사용자가 로그인하면 인증 완료를 알린다")
    func completedLoginSendsAuthenticated() async {
        let store = TestStore(initialState: AuthFeature.State()) {
            AuthFeature()
        } withDependencies: {
            $0.authFeatureClient = .mock(login: { _ in .completed(.sample) })
        }

        await store.send(.loginTapped(.kakao)) {
            $0.isSubmitting = true
        }
        await store.receive(\.loginResponse.success) {
            $0.isSubmitting = false
        }
        await store.receive(\.delegate, .authenticated(.sample))
    }

    @Test("가입이 필요하면 로그인한 제공자로 가입을 시작하게 한다")
    func pendingLoginSendsSignupRequired() async {
        let store = TestStore(initialState: AuthFeature.State()) {
            AuthFeature()
        } withDependencies: {
            $0.authFeatureClient = .mock(login: { .pending($0) })
        }

        await store.send(.loginTapped(.apple)) {
            $0.isSubmitting = true
        }
        await store.receive(\.loginResponse.success) {
            $0.isSubmitting = false
        }
        await store.receive(\.delegate, .signupRequired(.apple))
    }

    @Test("사용자가 로그인 창을 닫으면 안내하지 않는다")
    func cancelledLoginShowsNothing() async {
        let store = TestStore(initialState: AuthFeature.State()) {
            AuthFeature()
        } withDependencies: {
            $0.authFeatureClient = .mock(login: { _ in throw AuthError.cancelled })
        }

        await store.send(.loginTapped(.google)) {
            $0.isSubmitting = true
        }
        await store.receive(\.loginResponse.failure) {
            $0.isSubmitting = false
        }
    }

    @Test(
        "로그인 실패 종류에 맞는 안내를 보여 준다",
        arguments: [AuthError.inactiveAccount, .socialAccountConflict, .failed]
    )
    func failedLoginShowsMessage(error: AuthError) async {
        let store = TestStore(initialState: AuthFeature.State()) {
            AuthFeature()
        } withDependencies: {
            $0.authFeatureClient = .mock(login: { _ in throw error })
        }

        await store.send(.loginTapped(.kakao)) {
            $0.isSubmitting = true
        }
        await store.receive(\.loginResponse.failure) {
            $0.isSubmitting = false
            $0.errorMessage = AuthErrorMessage.login(for: error)
        }
        #expect(store.state.errorMessage != nil)

        await store.send(.errorDismissed) {
            $0.errorMessage = nil
        }
    }
}

@MainActor
struct RegisterFlowFeatureTests {
    @Test("가입에 성공하면 입력값으로 가입하고 완료 화면으로 간다")
    func completeRegistrationSignsUp() async {
        let receivedRequest = LockIsolated<(Provider, SignupRequest)?>(nil)
        let store = TestStore(initialState: makeState()) {
            RegisterFlowFeature()
        } withDependencies: {
            $0.authFeatureClient = .mock(signup: { provider, request in
                receivedRequest.setValue((provider, request))
                return .sample
            })
        }

        await store.send(.completeRegistrationTapped) {
            $0.isSubmitting = true
        }
        // S05: 가입에 성공해도 바로 메인으로 가지 않고 완료 화면을 보여 준다.
        await store.receive(\.completeRegistrationResponse.success) {
            $0.isSubmitting = false
            $0.signedUpUser = .sample
            $0.currentStep = .complete
        }

        #expect(receivedRequest.value?.0 == .google)
        #expect(receivedRequest.value?.1 == SignupRequest(
            nickname: "팝팡",
            isAlerted: true,
            fcmToken: nil,
            alertKeywordList: ["전시"],
            recommendList: [1, 2]
        ))
    }

    @Test(
        "가입 단계가 만료됐거나 탈퇴한 계정이면 안내와 함께 로그인부터 다시 하게 알린다",
        arguments: [AuthError.signupSessionExpired, .inactiveAccount]
    )
    func unrecoverableSignupReturnsToLogin(error: AuthError) async {
        let store = TestStore(initialState: makeState()) {
            RegisterFlowFeature()
        } withDependencies: {
            $0.authFeatureClient = .mock(signup: { _, _ in throw error })
        }
        let message = error == .signupSessionExpired
            ? AuthErrorMessage.signupSessionExpired
            : AuthErrorMessage.signup(for: error)

        await store.send(.completeRegistrationTapped) {
            $0.isSubmitting = true
        }
        await store.receive(\.completeRegistrationResponse.failure) {
            $0.isSubmitting = false
        }
        await store.receive(\.delegate, .loginRequired(errorMessage: message))
    }

    @Test("가입 화면의 닉네임 확인이 가입 단계 만료를 받으면 로그인부터 다시 하게 알린다")
    func nicknameCheckExpiryReturnsToLogin() async {
        var state = makeState()
        state.nickname = "팝팡이"
        let store = TestStore(initialState: state) {
            RegisterFlowFeature()
        } withDependencies: {
            $0.authFeatureClient = .mock(checkNickname: { _ in throw AuthError.signupSessionExpired })
        }

        await store.send(.validateNicknameTapped) {
            $0.isSubmitting = true
            $0.validationState = .checking
        }
        await store.receive(\.validateNicknameResponse) {
            $0.isSubmitting = false
            $0.validationState = .none
        }
        await store.receive(\.delegate, .loginRequired(errorMessage: AuthErrorMessage.signupSessionExpired))
    }

    @Test("관심 카테고리를 불러오지 못하면 카테고리 단계에 다시 시도를 보여 주고, 누르면 다시 받는다")
    func recommendListFailureCanRetry() async {
        let attempt = LockIsolated(0)
        let store = TestStore(initialState: makeState()) {
            RegisterFlowFeature()
        } withDependencies: {
            $0.authFeatureClient = .mock(getRecommendList: {
                let count = attempt.withValue { $0 += 1; return $0 }
                if count == 1 { throw AuthError.failed }
                return [Recommend(id: 1, recommendName: "디저트")]
            })
        }

        await store.send(.onAppear)
        await store.receive(\.recommendListResponse.failure) {
            $0.isRecommendListLoadFailed = true
        }
        // 닉네임 화면에는 안내하지 않는다.
        #expect(store.state.errorMessage == nil)

        await store.send(.retryRecommendListTapped) {
            $0.isRecommendListLoadFailed = false
        }
        await store.receive(\.recommendListResponse.success) {
            $0.recommendList = [Recommend(id: 1, recommendName: "디저트")]
        }
    }

    @Test("닉네임이 중복이면 닉네임 단계로 돌아가 안내한다")
    func duplicateNicknameReturnsToNicknameStep() async {
        var state = makeState()
        state.currentStep = .keyword
        let store = TestStore(initialState: state) {
            RegisterFlowFeature()
        } withDependencies: {
            $0.authFeatureClient = .mock(signup: { _, _ in throw AuthError.duplicateNickname })
        }

        await store.send(.completeRegistrationTapped) {
            $0.isSubmitting = true
        }
        await store.receive(\.completeRegistrationResponse.failure) {
            $0.isSubmitting = false
            $0.currentStep = .nickname
            $0.isForward = false
            // 중복 안내는 닉네임 확인 문구 하나만 보여 준다.
            $0.validationState = .duplicate
        }
    }

    @Test("닉네임 확인을 누른 뒤 닉네임을 고치면 늦게 온 확인 결과를 고친 닉네임에 붙이지 않는다")
    func staleNicknameCheckIsIgnored() async {
        let (gate, release) = AsyncStream.makeStream(of: Void.self)
        var state = makeState()
        state.nickname = "팝팡이"
        let store = TestStore(initialState: state) {
            RegisterFlowFeature()
        } withDependencies: {
            $0.authFeatureClient = .mock(checkNickname: { _ in
                for await _ in gate { break }
                return false
            })
        }

        await store.send(.validateNicknameTapped) {
            $0.isSubmitting = true
            $0.validationState = .checking
        }
        await store.send(.nicknameChanged("팝팡이다")) {
            $0.nickname = "팝팡이다"
            $0.validationState = .none
        }
        release.yield()
        await store.receive(\.validateNicknameResponse) {
            $0.isSubmitting = false
        }
        #expect(store.state.validationState == .none)
    }

    @Test("닉네임 확인을 누르면 아직 오지 않은 추천 닉네임으로 입력칸을 덮어쓰지 않는다")
    func validateCancelsPendingRecommendation() async {
        var state = makeState()
        state.nickname = "팝팡이"
        let store = TestStore(initialState: state) {
            RegisterFlowFeature()
        } withDependencies: {
            $0.authFeatureClient = .mock(
                checkNickname: { _ in false },
                recommendNickname: {
                    try await Task.sleep(for: .seconds(60))
                    return "설레는수달"
                }
            )
        }

        await store.send(.recommendNicknameTapped) {
            $0.isRecommendingNickname = true
        }
        await store.send(.validateNicknameTapped) {
            $0.isSubmitting = true
            $0.isRecommendingNickname = false
            $0.validationState = .checking
        }
        await store.receive(\.validateNicknameResponse) {
            $0.isSubmitting = false
            $0.validationState = .success
        }
        #expect(store.state.nickname == "팝팡이")
    }

    @Test("S02 닉네임 화면에 들어오면 추천 닉네임을 채우고 바로 쓸 수 있다고 표시한다")
    func s02OnAppearFillsRecommendedNickname() async {
        let store = TestStore(initialState: RegisterFlowFeature.State(provider: .google)) {
            RegisterFlowFeature()
        } withDependencies: {
            $0.authFeatureClient = .mock(
                getRecommendList: { [Recommend(id: 1, recommendName: "디저트")] },
                recommendNickname: { "설레는수달" }
            )
        }
        store.exhaustivity = .off(showSkippedAssertions: false)

        await store.send(.onAppear)
        await store.receive(\.nicknameRecommendationResponse.success) {
            $0.nickname = "설레는수달"
            $0.validationState = .success
        }
    }

    @Test("S02 다른 닉네임 추천받기를 누르면 새 추천 닉네임으로 바꾼다")
    func s02RecommendTappedReplacesNickname() async {
        var state = RegisterFlowFeature.State(provider: .google)
        state.nickname = "설레는수달"
        state.validationState = .success
        let store = TestStore(initialState: state) {
            RegisterFlowFeature()
        } withDependencies: {
            $0.authFeatureClient = .mock(recommendNickname: { "용감한판다" })
        }

        await store.send(.recommendNicknameTapped) {
            $0.isRecommendingNickname = true
        }
        await store.receive(\.nicknameRecommendationResponse.success) {
            $0.isRecommendingNickname = false
            $0.nickname = "용감한판다"
        }
    }

    @Test("S02 추천 닉네임을 받지 못하면 빈 칸으로 두고 안내하지 않는다")
    func s02RecommendationFailureKeepsEmptyField() async {
        var state = RegisterFlowFeature.State(provider: .google)
        state.recommendList = [Recommend(id: 1, recommendName: "디저트")]
        state.hasRequestedPopularKeywords = true
        let store = TestStore(initialState: state) {
            RegisterFlowFeature()
        } withDependencies: {
            $0.authFeatureClient = .mock(recommendNickname: { throw AuthError.failed })
        }

        await store.send(.onAppear) {
            $0.isRecommendingNickname = true
        }
        await store.receive(\.nicknameRecommendationResponse.failure) {
            $0.isRecommendingNickname = false
        }
    }

    @Test("S02 닉네임 추천이 가입 단계 만료를 받으면 로그인부터 다시 하게 알린다")
    func s02RecommendationExpiryReturnsToLogin() async {
        let store = TestStore(initialState: RegisterFlowFeature.State(provider: .google)) {
            RegisterFlowFeature()
        } withDependencies: {
            $0.authFeatureClient = .mock(recommendNickname: { throw AuthError.signupSessionExpired })
        }

        await store.send(.recommendNicknameTapped) {
            $0.isRecommendingNickname = true
        }
        await store.receive(\.nicknameRecommendationResponse.failure) {
            $0.isRecommendingNickname = false
        }
        await store.receive(\.delegate, .loginRequired(errorMessage: AuthErrorMessage.signupSessionExpired))
    }

    @Test("S02 이미 닉네임을 입력했으면 화면에 들어와도 추천으로 덮어쓰지 않는다")
    func s02OnAppearKeepsTypedNickname() async {
        var state = RegisterFlowFeature.State(provider: .google)
        state.nickname = "내닉네임"
        state.recommendList = [Recommend(id: 1, recommendName: "디저트")]
        state.hasRequestedPopularKeywords = true
        let store = TestStore(initialState: state) {
            RegisterFlowFeature()
        } withDependencies: {
            $0.authFeatureClient = .mock(recommendNickname: { "설레는수달" })
        }

        await store.send(.onAppear)
    }

    @Test("S03 카테고리 단계에서는 건너뛰기를 눌러도 키워드 단계로 넘어가지 않는다")
    func s03CategorySkipDoesNothing() async {
        var state = makeState()
        state.currentStep = .category
        state.selectedCategories = []
        let store = TestStore(initialState: state) {
            RegisterFlowFeature()
        }

        await store.send(.skipTapped)
    }

    @Test("S03 카테고리를 하나도 고르지 않으면 다음으로 가지 않는다")
    func s03NextWithoutCategoryStays() async {
        var state = makeState()
        state.currentStep = .category
        state.selectedCategories = []
        let store = TestStore(initialState: state) {
            RegisterFlowFeature()
        }

        await store.send(.nextFromCategoryTapped)
    }

    @Test("S03 칩을 누르면 선택하고, 다시 누르면 선택을 푼다")
    func s03CategoryToggleSelectsAndDeselects() async {
        var state = makeState()
        state.currentStep = .category
        state.selectedCategories = []
        let store = TestStore(initialState: state) {
            RegisterFlowFeature()
        }

        await store.send(.categoryToggled(3)) {
            $0.selectedCategories = [3]
        }
        await store.send(.categoryToggled(5)) {
            $0.selectedCategories = [3, 5]
        }
        await store.send(.categoryToggled(3)) {
            $0.selectedCategories = [5]
        }
        await store.send(.nextFromCategoryTapped) {
            $0.currentStep = .keyword
        }
    }

    @Test("S04 가입 흐름에 들어오면 인기 키워드를 한 번 받아 둔다")
    func s04OnAppearLoadsPopularKeywords() async {
        let callCount = LockIsolated(0)
        var state = makeState()
        state.hasRequestedPopularKeywords = false
        state.recommendList = [Recommend(id: 1, recommendName: "디저트")]
        let store = TestStore(initialState: state) {
            RegisterFlowFeature()
        } withDependencies: {
            $0.authFeatureClient = .mock(getPopularKeywords: {
                callCount.withValue { $0 += 1 }
                return ["소금빵", "베이글"]
            })
        }

        await store.send(.onAppear) {
            $0.hasRequestedPopularKeywords = true
        }
        await store.receive(\.popularKeywordsResponse.success) {
            $0.popularKeywords = ["소금빵", "베이글"]
        }
        await store.send(.onAppear)
        #expect(callCount.value == 1)
    }

    @Test("S04 인기 키워드를 받지 못하면 빈 목록으로 두고 안내하지 않는다")
    func s04PopularKeywordsFailureKeepsEmpty() async {
        var state = makeState()
        state.hasRequestedPopularKeywords = false
        state.recommendList = [Recommend(id: 1, recommendName: "디저트")]
        let store = TestStore(initialState: state) {
            RegisterFlowFeature()
        } withDependencies: {
            $0.authFeatureClient = .mock(getPopularKeywords: { throw AuthError.failed })
        }

        await store.send(.onAppear) {
            $0.hasRequestedPopularKeywords = true
        }
        await store.receive(\.popularKeywordsResponse.failure)
        #expect(store.state.popularKeywords.isEmpty)
        #expect(store.state.errorMessage == nil)
    }

    @Test("S04 인기 키워드를 누르면 입력 중인 글자는 두고 내 키워드에 더한다")
    func s04PopularKeywordTapAddsKeyword() async {
        var state = makeState()
        state.currentStep = .keyword
        state.keywordInput = "짱"
        state.popularKeywords = ["소금빵", "전시"]
        let store = TestStore(initialState: state) {
            RegisterFlowFeature()
        }

        await store.send(.popularKeywordTapped("소금빵")) {
            $0.keywords = ["전시", "소금빵"]
        }
        // 이미 있는 키워드는 다시 더하지 않는다.
        await store.send(.popularKeywordTapped("전시"))
    }

    @Test("S04 내 키워드가 5개면 인기 키워드도 직접 입력도 더하지 않고 제한 알림을 띄운다")
    func s04KeywordLimitIsFive() async {
        var state = makeState()
        state.currentStep = .keyword
        state.keywords = ["가", "나", "다", "라"]
        let store = TestStore(initialState: state) {
            RegisterFlowFeature()
        }

        await store.send(.popularKeywordTapped("마")) {
            $0.keywords = ["가", "나", "다", "라", "마"]
        }
        await store.send(.popularKeywordTapped("바")) {
            $0.isKeywordLimitAlertPresented = true
        }
        await store.send(.keywordLimitAlertDismissed) {
            $0.isKeywordLimitAlertPresented = false
        }
        await store.send(.keywordInputChanged("사")) {
            $0.keywordInput = "사"
        }
        await store.send(.keywordAdded("사")) {
            $0.isKeywordLimitAlertPresented = true
        }
        #expect(store.state.keywords.count == RegisterFlowFeature.maxKeywordCount)
    }

    @Test("S04 인기 키워드 요청이 가입 단계 만료를 받으면 로그인부터 다시 하게 알린다")
    func s04PopularKeywordsExpiryReturnsToLogin() async {
        var state = makeState()
        state.hasRequestedPopularKeywords = false
        state.recommendList = [Recommend(id: 1, recommendName: "디저트")]
        let store = TestStore(initialState: state) {
            RegisterFlowFeature()
        } withDependencies: {
            $0.authFeatureClient = .mock(getPopularKeywords: { throw AuthError.signupSessionExpired })
        }

        await store.send(.onAppear) {
            $0.hasRequestedPopularKeywords = true
        }
        await store.receive(\.popularKeywordsResponse.failure)
        await store.receive(\.delegate, .loginRequired(errorMessage: AuthErrorMessage.signupSessionExpired))
    }

    @Test("S05 키워드 단계에서 가입에 성공하면 완료 화면으로 가고 아직 완료를 알리지 않는다")
    func s05SignupSuccessShowsCompleteStep() async {
        var state = makeState()
        state.currentStep = .keyword
        let store = TestStore(initialState: state) {
            RegisterFlowFeature()
        } withDependencies: {
            $0.authFeatureClient = .mock(signup: { _, _ in .sample })
        }

        await store.send(.skipTapped) {
            // 건너뛰면 이미 넣은 키워드도 등록하지 않는다.
            $0.keywords = []
        }
        await store.receive(\.completeRegistrationTapped) {
            $0.isSubmitting = true
        }
        await store.receive(\.completeRegistrationResponse.success) {
            $0.isSubmitting = false
            $0.signedUpUser = .sample
            $0.currentStep = .complete
        }
        // 완료 화면에서는 뒤로 가지 않는다.
        await store.send(.backTapped)
    }

    @Test("키워드 단계에서 건너뛰기를 누르면 넣어 둔 키워드 없이 알림을 끈 채 가입한다")
    func skipSignsUpWithoutKeywords() async {
        let request = LockIsolated<SignupRequest?>(nil)
        var state = makeState()
        state.currentStep = .keyword
        state.keywords = ["두쫀쿠"]
        state.keywordInput = "짱"
        let store = TestStore(initialState: state) {
            RegisterFlowFeature()
        } withDependencies: {
            $0.authFeatureClient = .mock(signup: { _, sent in
                request.setValue(sent)
                return .sample
            })
        }
        store.exhaustivity = .off(showSkippedAssertions: false)

        await store.send(.skipTapped) {
            $0.keywords = []
            $0.keywordInput = ""
        }
        await store.receive(\.completeRegistrationResponse.success)
        #expect(request.value?.alertKeywordList == [])
        #expect(request.value?.isAlerted == false)
    }

    @Test("추천 닉네임을 받는 동안에는 다음으로 가지 않는다")
    func nextIsBlockedWhileRecommending() async {
        let (gate, release) = AsyncStream.makeStream(of: Void.self)
        var state = makeState()
        state.nickname = "팝팡이"
        state.validationState = .success
        let store = TestStore(initialState: state) {
            RegisterFlowFeature()
        } withDependencies: {
            $0.authFeatureClient = .mock(recommendNickname: {
                for await _ in gate { break }
                return "설레는수달"
            })
        }

        await store.send(.recommendNicknameTapped) {
            $0.isRecommendingNickname = true
        }
        // 응답 전에는 다음을 눌러도 닉네임 단계에 머문다.
        await store.send(.nextFromNicknameTapped)
        release.yield()
        await store.receive(\.nicknameRecommendationResponse.success) {
            $0.isRecommendingNickname = false
            $0.nickname = "설레는수달"
        }
        await store.send(.nextFromNicknameTapped) {
            $0.currentStep = .category
        }
    }

    @Test("닉네임 확인은 입력할 때와 같은 규칙으로 먼저 거른다")
    func validateUsesLocalRules() async {
        let store = TestStore(initialState: makeState()) {
            RegisterFlowFeature()
        }

        await store.send(.nicknameChanged("")) {
            $0.nickname = ""
        }
        await store.send(.validateNicknameTapped) {
            // 빈 칸은 너무 짧은 닉네임으로 본다.
            $0.validationState = .tooShort
        }
        await store.send(.nicknameChanged("팝 팡이")) {
            $0.nickname = "팝 팡이"
            $0.validationState = .invalidSpace
        }
        await store.send(.validateNicknameTapped)
    }

    @Test("S05 시작하기를 누르면 알림 권한을 묻지 않고 바로 완료를 알린다")
    func s05StartCompletesImmediately() async {
        var state = makeState()
        state.currentStep = .complete
        state.signedUpUser = .sample
        let store = TestStore(initialState: state) {
            RegisterFlowFeature()
        }

        await store.send(.startTapped)
        await store.receive(\.delegate, .completed(.sample))
    }

    private func makeState() -> RegisterFlowFeature.State {
        var state = RegisterFlowFeature.State(provider: .google)
        state.nickname = "팝팡"
        state.selectedCategories = [1, 2]
        state.keywords = ["전시"]
        // 인기 키워드 요청은 S04 테스트에서 따로 확인한다.
        state.hasRequestedPopularKeywords = true
        return state
    }
}

private extension User {
    static let sample = User(
        userUuid: "user-1",
        provider: .kakao,
        email: nil,
        nickname: "팝팡",
        role: .member,
        isAlerted: false
    )
}

private extension AuthFeatureClient {
    static func mock(
        login: @escaping @Sendable (Provider) async throws -> LoginResult = { _ in throw AuthError.failed },
        signup: @escaping @Sendable (Provider, SignupRequest) async throws -> User = { _, _ in throw AuthError.failed },
        checkNickname: @escaping @Sendable (String) async throws -> Bool = { _ in false },
        getRecommendList: @escaping @Sendable () async throws -> [Recommend] = { [] },
        recommendNickname: @escaping @Sendable () async throws -> String = { throw AuthError.failed },
        getPopularKeywords: @escaping @Sendable () async throws -> [String] = { [] }
    ) -> Self {
        AuthFeatureClient(
            login: login,
            signup: signup,
            checkNickname: checkNickname,
            getRecommendList: getRecommendList,
            recommendNickname: recommendNickname,
            getPopularKeywords: getPopularKeywords
        )
    }
}
