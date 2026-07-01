import AuthenticationServices
import ComposableArchitecture
import Domain

public struct AuthFeatureClient: Sendable {
    public var kakaoLogin: @Sendable () async throws -> User
    public var googleLogin: @Sendable () async throws -> User
    public var appleLogin: @Sendable (ASAuthorization) async throws -> User
    public var kakaoRegister: @Sendable (User) async throws -> User
    public var googleRegister: @Sendable (User) async throws -> User
    public var appleRegister: @Sendable (User) async throws -> User
    public var checkNickname: @Sendable (String) async throws -> Bool
    public var getRecommendList: @Sendable () async throws -> [Recommend]

    public init(
        kakaoLogin: @escaping @Sendable () async throws -> User,
        googleLogin: @escaping @Sendable () async throws -> User,
        appleLogin: @escaping @Sendable (ASAuthorization) async throws -> User,
        kakaoRegister: @escaping @Sendable (User) async throws -> User,
        googleRegister: @escaping @Sendable (User) async throws -> User,
        appleRegister: @escaping @Sendable (User) async throws -> User,
        checkNickname: @escaping @Sendable (String) async throws -> Bool,
        getRecommendList: @escaping @Sendable () async throws -> [Recommend]
    ) {
        self.kakaoLogin = kakaoLogin
        self.googleLogin = googleLogin
        self.appleLogin = appleLogin
        self.kakaoRegister = kakaoRegister
        self.googleRegister = googleRegister
        self.appleRegister = appleRegister
        self.checkNickname = checkNickname
        self.getRecommendList = getRecommendList
    }

    public static func live(
        kakaoAuthUsecase: KakaoAuthUsecaseProtocol,
        googleAuthUsecase: GoogleAuthUsecaseProtocol,
        appleAuthUsecase: AppleAuthUsecaseProtocol,
        userUsecase: UserUsecaseProtocol
    ) -> Self {
        let kakaoAuthUsecaseBox = KakaoAuthUsecaseBox(kakaoAuthUsecase)
        let googleAuthUsecaseBox = GoogleAuthUsecaseBox(googleAuthUsecase)
        let appleAuthUsecaseBox = AppleAuthUsecaseBox(appleAuthUsecase)
        let userUsecaseBox = UserUsecaseBox(userUsecase)

        return AuthFeatureClient(
            kakaoLogin: {
                try await kakaoAuthUsecaseBox.usecase.kakaoLogin()
            },
            googleLogin: {
                try await googleAuthUsecaseBox.usecase.googleLogin()
            },
            appleLogin: { authorization in
                try await appleAuthUsecaseBox.usecase.appleLogin(authorization: authorization)
            },
            kakaoRegister: { user in
                try await kakaoAuthUsecaseBox.usecase.kakaoRegister(user: user)
            },
            googleRegister: { user in
                try await googleAuthUsecaseBox.usecase.googleRegister(user: user)
            },
            appleRegister: { user in
                try await appleAuthUsecaseBox.usecase.appleRegister(user: user)
            },
            checkNickname: { nickname in
                try await userUsecaseBox.usecase.checkNickname(nickname: nickname)
            },
            getRecommendList: {
                try await userUsecaseBox.usecase.getRecommandList()
            }
        )
    }
}

private struct AuthFeatureUnimplementedError: Error {}

extension AuthFeatureClient {
    public static let unimplemented = Self(
        kakaoLogin: { throw AuthFeatureUnimplementedError() },
        googleLogin: { throw AuthFeatureUnimplementedError() },
        appleLogin: { _ in throw AuthFeatureUnimplementedError() },
        kakaoRegister: { _ in throw AuthFeatureUnimplementedError() },
        googleRegister: { _ in throw AuthFeatureUnimplementedError() },
        appleRegister: { _ in throw AuthFeatureUnimplementedError() },
        checkNickname: { _ in throw AuthFeatureUnimplementedError() },
        getRecommendList: { throw AuthFeatureUnimplementedError() }
    )
}

private final class KakaoAuthUsecaseBox: @unchecked Sendable {
    let usecase: KakaoAuthUsecaseProtocol

    init(_ usecase: KakaoAuthUsecaseProtocol) {
        self.usecase = usecase
    }
}

private final class GoogleAuthUsecaseBox: @unchecked Sendable {
    let usecase: GoogleAuthUsecaseProtocol

    init(_ usecase: GoogleAuthUsecaseProtocol) {
        self.usecase = usecase
    }
}

private final class AppleAuthUsecaseBox: @unchecked Sendable {
    let usecase: AppleAuthUsecaseProtocol

    init(_ usecase: AppleAuthUsecaseProtocol) {
        self.usecase = usecase
    }
}

private final class UserUsecaseBox: @unchecked Sendable {
    let usecase: UserUsecaseProtocol

    init(_ usecase: UserUsecaseProtocol) {
        self.usecase = usecase
    }
}

extension AuthFeatureClient: DependencyKey {
    public static let liveValue = Self.unimplemented
}

extension AuthFeatureClient: TestDependencyKey {
    public static let testValue = Self.unimplemented
}

extension DependencyValues {
    public var authFeatureClient: AuthFeatureClient {
        get { self[AuthFeatureClient.self] }
        set { self[AuthFeatureClient.self] = newValue }
    }
}
