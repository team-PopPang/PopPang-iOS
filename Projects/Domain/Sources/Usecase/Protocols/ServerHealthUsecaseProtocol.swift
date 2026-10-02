public protocol ServerHealthUsecaseProtocol {
    /// 서버 헬스 체크
    /// - Returns: 정상, 서버 이상, 오프라인 중 하나. 실패해도 오류를 던지지 않는다.
    func checkHealth() async -> ServerHealth
}
