import AuthenticationServices

public final class AppleAuthUsecaseImpl: AppleAuthUsecaseProtocol {
    private let appleAuthRepository: AppleAuthRepositoryProtocol

    public init(appleAuthRepository: AppleAuthRepositoryProtocol) {
        self.appleAuthRepository = appleAuthRepository
    }

    public func appleLogin(authorization: ASAuthorization) async throws -> User {
        try await appleAuthRepository.appleLogin(authorization: authorization)
    }

    public func appleRegister(user: User) async throws -> User {
        try await appleAuthRepository.appleRegister(user: user)
    }
}
