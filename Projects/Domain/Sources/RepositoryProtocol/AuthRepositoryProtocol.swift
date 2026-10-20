public protocol AuthRepositoryProtocol {
    /// 소셜 로그인 후 서버 로그인을 한다.
    /// - Throws: `AuthError`
    func login(with provider: Provider) async throws -> LoginResult

    /// `login(with:)`가 `.pending`을 돌려준 뒤 가입을 마친다.
    /// - Throws: `AuthError`
    func signup(with provider: Provider, request: SignupRequest) async throws -> User

    /// 진행 중인 가입을 취소한다.
    func cancelSignup()

    /// 저장된 토큰으로 로그인 상태를 되살린다.
    /// - Returns: 로그인 상태가 아니면 `nil`
    /// - Throws: 서버 오류나 네트워크 문제로 확인하지 못했을 때. 이때 저장된 토큰은 지우지 않는다.
    func restoreSession() async throws -> User?

    /// 서버 로그아웃을 요청하고, 결과와 관계없이 기기의 토큰을 지운다.
    func logout() async
}
