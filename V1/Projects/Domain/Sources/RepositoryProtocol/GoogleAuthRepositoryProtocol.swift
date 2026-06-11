public enum GoogleAuthError: Error {
    case noRootViewController
    case noUser
}

public protocol GoogleAuthRepositoryProtocol {
    /// 구글 로그인
    /// - 앱 설치 유무에 따라 앱로그인 또는 웹뷰로 로그인을 진행합니다
    /// - Returns: User
    func googleLogin() async throws -> User

    /// 구글 회원가입
    /// - Parameter user: 회원가입 정보
    /// - Returns: 유저 정보
    func googleRegister(user: User) async throws -> User
}
