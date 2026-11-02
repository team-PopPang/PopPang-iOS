public protocol AuthUsecaseProtocol {
    /// 소셜 로그인 후 서버 로그인을 한다.
    /// - Throws: `AuthError`
    func login(with provider: Provider) async throws -> LoginResult

    /// 가입을 마친다.
    /// - Throws: `AuthError`
    func signup(with provider: Provider, request: SignupRequest) async throws -> User

    /// 가입 화면에서 닉네임이 이미 쓰이는지 확인한다. 가입 전용 토큰으로 부른다.
    /// - Throws: `AuthError`
    func checkSignupNickname(_ nickname: String) async throws -> Bool

    /// 가입 화면에서 고를 관심 카테고리 목록. 가입 전용 토큰으로 부른다.
    /// - Throws: `AuthError`
    func fetchSignupRecommendList() async throws -> [Recommend]

    /// 가입 화면에 미리 채울 랜덤 닉네임. 가입 전용 토큰으로 부른다.
    /// 추천은 예약이 아니라서 가입할 때 다시 중복을 확인한다.
    /// - Throws: `AuthError`
    func recommendSignupNickname() async throws -> String

    /// 가입 화면 키워드 단계의 인기 키워드. 가입 전용 토큰으로 부른다. 최대 6개이고 없으면 빈 배열이다.
    /// - Throws: `AuthError`
    func fetchPopularKeywords() async throws -> [String]

    /// 저장된 토큰으로 로그인 상태를 되살린다.
    /// - Returns: 로그인 상태가 아니면 `nil`
    func restoreSession() async throws -> User?

    /// 로그아웃한다.
    func logout() async
}
