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

    @Test("가입 단계가 만료되면 로그인부터 다시 하게 알린다")
    func expiredSignupSendsSessionExpired() async {
        let store = TestStore(initialState: makeState()) {
            RegisterFlowFeature()
        } withDependencies: {
            $0.authFeatureClient = .mock(signup: { _, _ in throw AuthError.signupSessionExpired })
        }

        await store.send(.completeRegistrationTapped) {
            $0.isSubmitting = true
        }
        await store.receive(\.completeRegistrationResponse.failure) {
            $0.isSubmitting = false
        }
        await store.receive(\.delegate, .signupSessionExpired)
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
        signup: @escaping @Sendable (Provider, SignupRequest) async throws -> User = { _, _ in throw AuthError.failed }
    ) -> Self {
        AuthFeatureClient(
            login: login,
            signup: signup,
            checkNickname: { _ in false },
            getRecommendList: { [] }
        )
    }
}
