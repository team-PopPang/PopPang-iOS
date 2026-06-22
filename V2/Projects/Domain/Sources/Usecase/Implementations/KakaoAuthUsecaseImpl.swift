public final class KakaoAuthUsecaseImpl: KakaoAuthUsecaseProtocol {
    private let kakaoAuthRepository: KakaoAuthRepositoryProtocol

    public init(kakaoAuthRepository: KakaoAuthRepositoryProtocol) {
        self.kakaoAuthRepository = kakaoAuthRepository
    }

    public func kakaoLogin() async throws -> User {
        try await kakaoAuthRepository.kakaoLogin()
    }

    public func kakaoRegister(user: User) async throws -> User {
        try await kakaoAuthRepository.kakaoRegister(user: user)
    }
}
