/// 알림 키워드 요청에서 화면이 다르게 처리해야 하는 실패
public enum AlertKeywordError: Error, Equatable, Sendable {
    /// 서버에 이미 같은 키워드가 있다.
    case alreadyExists
    /// 그 밖의 실패. 잠시 후 다시 시도한다.
    case failed
}
