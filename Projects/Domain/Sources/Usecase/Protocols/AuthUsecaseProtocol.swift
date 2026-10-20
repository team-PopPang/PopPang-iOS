public protocol AuthUsecaseProtocol {
    /// 소셜 로그인 후 서버 로그인을 한다.
    /// - Throws: `AuthError`
    func login(with provider: Provider) async throws -> LoginResult

    /// 가입을 마친다.
    /// - Throws: `AuthError`
    func signup(with provider: Provider, request: SignupRequest) async throws -> User

    /// 진행 중인 가입을 취소한다.
    func cancelSignup()

    /// 저장된 토큰으로 로그인 상태를 되살린다.
    /// - Returns: 로그인 상태가 아니면 `nil`
    func restoreSession() async throws -> User?

    /// 로그아웃한다.
    func logout() async
}
