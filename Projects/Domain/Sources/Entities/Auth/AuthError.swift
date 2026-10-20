/// 로그인·가입에서 화면이 다르게 안내해야 하는 실패
public enum AuthError: Error, Equatable, Sendable {
    /// 사용자가 소셜 로그인 창을 닫았다. 안내하지 않는다.
    case cancelled
    /// 탈퇴한 계정이다.
    case inactiveAccount
    /// 같은 소셜 계정이 다른 방식으로 이미 가입돼 있다.
    case socialAccountConflict
    /// 가입 단계가 만료됐거나 이미 끝났다. 소셜 로그인부터 다시 해야 한다.
    case signupSessionExpired
    /// 이미 쓰는 닉네임이다.
    case duplicateNickname
    /// 가입 입력값이 서버 기준에 맞지 않는다.
    case invalidSignupRequest
    /// 그 밖의 실패. 잠시 후 다시 시도한다.
    case failed
}
