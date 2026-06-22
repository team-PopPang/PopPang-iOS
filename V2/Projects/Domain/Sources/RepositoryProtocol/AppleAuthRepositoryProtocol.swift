import AuthenticationServices

public enum AppleAuthRepositoryError: Error {
    case authCodeNotFound
}

public protocol AppleAuthRepositoryProtocol {
    /// 애플 로그인
    /// - Parameter authorization: authCode를 PopPang 서버로 보낸 후 유저 정보를 받습니다
    /// - Returns: User
    func appleLogin(authorization: ASAuthorization) async throws -> User

    /// 애플 회원가입
    /// - Parameter user: 회원가입 정보
    /// - Returns: 유저 정보
    func appleRegister(user: User) async throws -> User
}
