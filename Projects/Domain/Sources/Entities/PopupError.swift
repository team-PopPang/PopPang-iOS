/// 팝업 조회에서 화면이 안내해야 하는 실패
///
/// 다시 로그인해야 하는 실패는 이 타입으로 바꾸지 않는다. 그때는 앱이 로그인 화면으로 보낸다.
public enum PopupError: Error, Equatable, Sendable {
    /// 서버 오류나 네트워크 문제로 불러오지 못했다. 잠시 후 다시 시도한다.
    case failed
}
