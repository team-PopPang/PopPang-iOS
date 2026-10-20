public final class AuthUsecaseImpl: AuthUsecaseProtocol {
    private let authRepository: AuthRepositoryProtocol

    public init(authRepository: AuthRepositoryProtocol) {
        self.authRepository = authRepository
    }

    public func login(with provider: Provider) async throws -> LoginResult {
        try await authRepository.login(with: provider)
    }

    public func signup(with provider: Provider, request: SignupRequest) async throws -> User {
        try await authRepository.signup(with: provider, request: request)
    }

    public func cancelSignup() {
        authRepository.cancelSignup()
    }

    public func restoreSession() async throws -> User? {
        try await authRepository.restoreSession()
    }

    public func logout() async {
        await authRepository.logout()
    }
}
