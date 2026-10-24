import ComposableArchitecture
import Domain
import Foundation
import Testing
@testable import AuthFeature

@MainActor
struct AuthFeatureTests {
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
    @Test("가입에 성공하면 입력값으로 가입하고 완료를 알린다")
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
        await store.receive(\.completeRegistrationResponse.success) {
            $0.isSubmitting = false
        }
        await store.receive(\.delegate, .completed(.sample))

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
        await store.receive(\.validateNicknameResponse.failure) {
            $0.isSubmitting = false
            $0.validationState = .none
        }
        await store.receive(\.delegate, .loginRequired(errorMessage: AuthErrorMessage.signupSessionExpired))
    }

    @Test("관심 카테고리를 불러오지 못하면 안내한다")
    func recommendListFailureShowsMessage() async {
        let store = TestStore(initialState: makeState()) {
            RegisterFlowFeature()
        } withDependencies: {
            $0.authFeatureClient = .mock(getRecommendList: { throw AuthError.failed })
        }

        await store.send(.onAppear)
        await store.receive(\.recommendListResponse.failure) {
            $0.errorMessage = AuthErrorMessage.recommendListLoadFailed
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
            $0.validationState = .duplicate
            $0.errorMessage = AuthErrorMessage.signup(for: AuthError.duplicateNickname)
        }
    }

    private func makeState() -> RegisterFlowFeature.State {
        var state = RegisterFlowFeature.State(provider: .google)
        state.nickname = "팝팡"
        state.selectedCategories = [1, 2]
        state.keywords = ["전시"]
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
        getRecommendList: @escaping @Sendable () async throws -> [Recommend] = { [] }
    ) -> Self {
        AuthFeatureClient(
            login: login,
            signup: signup,
            checkNickname: checkNickname,
            getRecommendList: getRecommendList
        )
    }
}
