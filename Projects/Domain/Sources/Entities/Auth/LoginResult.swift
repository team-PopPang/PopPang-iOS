/// 소셜 로그인 결과
public enum LoginResult: Equatable, Sendable {
    /// 가입을 마친 사용자다. 토큰은 Data가 저장했다.
    case completed(User)
    /// 가입이 필요하다. 가입 전용 토큰은 Data가 저장했다.
    case pending(Provider)
}
