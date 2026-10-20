import ComposableArchitecture
import Domain

public struct AuthFeatureClient: Sendable {
    public var login: @Sendable (Provider) async throws -> LoginResult
    public var signup: @Sendable (Provider, SignupRequest) async throws -> User
    public var checkNickname: @Sendable (String) async throws -> Bool
    public var getRecommendList: @Sendable () async throws -> [Recommend]

    public init(
        login: @escaping @Sendable (Provider) async throws -> LoginResult,
        signup: @escaping @Sendable (Provider, SignupRequest) async throws -> User,
        checkNickname: @escaping @Sendable (String) async throws -> Bool,
        getRecommendList: @escaping @Sendable () async throws -> [Recommend]
    ) {
        self.login = login
        self.signup = signup
        self.checkNickname = checkNickname
        self.getRecommendList = getRecommendList
    }

    public static func live(
        authUsecase: AuthUsecaseProtocol,
        userUsecase: UserUsecaseProtocol
    ) -> Self {
        let authUsecaseBox = AuthUsecaseBox(authUsecase)
        let userUsecaseBox = UserUsecaseBox(userUsecase)

        return AuthFeatureClient(
            login: { provider in
                try await authUsecaseBox.usecase.login(with: provider)
            },
            signup: { provider, request in
                try await authUsecaseBox.usecase.signup(with: provider, request: request)
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
        login: { _ in throw AuthFeatureUnimplementedError() },
        signup: { _, _ in throw AuthFeatureUnimplementedError() },
        checkNickname: { _ in throw AuthFeatureUnimplementedError() },
        getRecommendList: { throw AuthFeatureUnimplementedError() }
    )
}

private final class AuthUsecaseBox: @unchecked Sendable {
    let usecase: AuthUsecaseProtocol

    init(_ usecase: AuthUsecaseProtocol) {
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
