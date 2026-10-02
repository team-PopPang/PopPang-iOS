/// 앱 시작 시 확인하는 서버 헬스 체크 결과
public enum ServerHealth: Equatable, Sendable {
    /// 서버가 정상 응답했다
    case healthy

    /// 서버가 응답하지 않거나 정상 응답이 아니다
    case unhealthy

    /// 기기가 인터넷에 연결되어 있지 않다
    case offline
}
