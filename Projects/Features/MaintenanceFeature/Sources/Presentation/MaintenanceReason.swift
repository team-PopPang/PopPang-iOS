/// 점검 화면을 띄운 이유
public enum MaintenanceReason: Equatable, Sendable {
    /// 서버가 응답하지 않거나 정상 응답이 아니다
    case serverUnavailable

    /// 기기가 인터넷에 연결되어 있지 않다
    case offline
}
