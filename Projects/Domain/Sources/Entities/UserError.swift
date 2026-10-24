/// 내 정보 변경에서 화면이 다르게 안내해야 하는 실패
public enum UserError: Error, Equatable, Sendable {
    /// 이미 쓰는 닉네임이다.
    case duplicateNickname
    /// 닉네임이 서버 기준에 맞지 않는다. 빈 값이나 공백만 있는 값이다.
    case invalidNickname
    /// 그 밖의 실패. 잠시 후 다시 시도한다.
    case failed
}
