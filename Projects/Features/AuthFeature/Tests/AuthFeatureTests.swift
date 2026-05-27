@preconcurrency import AuthenticationServices
import Core
import Domain
import Foundation
import Testing
@testable import AuthFeature

struct AuthFeatureTests {
    @Test
    @MainActor
    func kakaoLoginCallsUsecaseAndCompletesAuthenticationLikeV0() async {
        let kakaoUsecase = MockKakaoAuthUsecase(user: makeUser(userUuid: "kakao-user", provider: "KAKAO"))
        DIContainer.shared.register(kakaoUsecase, for: KakaoAuthUsecaseProtocol.self)
        DIContainer.shared.register(MockGoogleAuthUsecase(), for: GoogleAuthUsecaseProtocol.self)
        DIContainer.shared.register(MockAppleAuthUsecase(), for: AppleAuthUsecaseProtocol.self)

        var completedUser: User?
        let compound = AuthFeatureCompound { user in
            completedUser = user
        }

        let state = await reduceAll(compound, action: .kakaoLogin)

        #expect(kakaoUsecase.loginCallCount == 1)
        #expect(completedUser?.userUuid == "kakao-user")
        #expect(state.isSubmitting == false)
        #expect(state.errorMessage == nil)
    }

    @Test
    @MainActor
    func googleLoginCallsUsecaseAndCompletesAuthenticationLikeV0() async {
        let googleUsecase = MockGoogleAuthUsecase(user: makeUser(userUuid: "google-user", provider: "GOOGLE"))
        DIContainer.shared.register(MockKakaoAuthUsecase(), for: KakaoAuthUsecaseProtocol.self)
        DIContainer.shared.register(googleUsecase, for: GoogleAuthUsecaseProtocol.self)
        DIContainer.shared.register(MockAppleAuthUsecase(), for: AppleAuthUsecaseProtocol.self)

        var completedUser: User?
        let compound = AuthFeatureCompound { user in
            completedUser = user
        }

        let state = await reduceAll(compound, action: .googleLogin)

        #expect(googleUsecase.loginCallCount == 1)
        #expect(completedUser?.userUuid == "google-user")
        #expect(state.isSubmitting == false)
        #expect(state.errorMessage == nil)
    }

    @Test
    @MainActor
    func loginFailureKeepsUserOnAuthStateWithErrorMessage() async {
        DIContainer.shared.register(MockKakaoAuthUsecase(error: TestError.loginFailed), for: KakaoAuthUsecaseProtocol.self)
        DIContainer.shared.register(MockGoogleAuthUsecase(), for: GoogleAuthUsecaseProtocol.self)
        DIContainer.shared.register(MockAppleAuthUsecase(), for: AppleAuthUsecaseProtocol.self)

        var completedUser: User?
        let compound = AuthFeatureCompound { user in
            completedUser = user
        }

        let state = await reduceAll(compound, action: .kakaoLogin)

        #expect(completedUser == nil)
        #expect(state.isSubmitting == false)
        #expect(state.errorMessage == TestError.loginFailed.localizedDescription)
    }

    private func reduceAll(
        _ compound: AuthFeatureCompound,
        action: AuthFeatureCompound.Action,
        initialState: AuthFeatureCompound.State? = nil
    ) async -> AuthFeatureCompound.State {
        var state = initialState ?? compound.state

        for await reaction in compound.react(action: action) {
            state = compound.reduce(state: state, reaction: reaction)
        }

        return state
    }
}

private enum TestError: LocalizedError {
    case loginFailed

    var errorDescription: String? {
        "로그인 실패"
    }
}

private final class MockKakaoAuthUsecase: KakaoAuthUsecaseProtocol {
    private(set) var loginCallCount = 0
    private let user: User
    private let error: Error?

    init(user: User = makeUser(userUuid: "kakao-user", provider: "KAKAO"), error: Error? = nil) {
        self.user = user
        self.error = error
    }

    func kakaoLogin() async throws -> User {
        loginCallCount += 1
        if let error { throw error }
        return user
    }

    func kakaoRegister(user: User) async throws -> User {
        user
    }
}

private final class MockGoogleAuthUsecase: GoogleAuthUsecaseProtocol {
    private(set) var loginCallCount = 0
    private let user: User
    private let error: Error?

    init(user: User = makeUser(userUuid: "google-user", provider: "GOOGLE"), error: Error? = nil) {
        self.user = user
        self.error = error
    }

    func googleLogin() async throws -> User {
        loginCallCount += 1
        if let error { throw error }
        return user
    }

    func googleRegister(user: User) async throws -> User {
        user
    }
}

private final class MockAppleAuthUsecase: AppleAuthUsecaseProtocol {
    func appleLogin(authorization: ASAuthorization) async throws -> User {
        makeUser(userUuid: "apple-user", provider: "APPLE")
    }

    func appleRegister(user: User) async throws -> User {
        user
    }
}

private func makeUser(
    userUuid: String,
    provider: String,
    nickname: String? = "팝팡"
) -> User {
    User(
        userUuid: userUuid,
        uid: "\(provider)-uid",
        provider: provider,
        email: "test@example.com",
        nickname: nickname,
        role: "USER",
        isAlerted: true,
        fcmToken: nil,
        alertKeywordList: [],
        recommendList: []
    )
}
