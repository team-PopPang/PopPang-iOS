public final class GoogleAuthUsecaseImpl: GoogleAuthUsecaseProtocol {
    private let googleAuthRepository: GoogleAuthRepositoryProtocol

    public init(googleAuthRepository: GoogleAuthRepositoryProtocol) {
        self.googleAuthRepository = googleAuthRepository
    }

    public func googleLogin() async throws -> User {
        try await googleAuthRepository.googleLogin()
    }

    public func googleRegister(user: User) async throws -> User {
        try await googleAuthRepository.googleRegister(user: user)
    }
}
