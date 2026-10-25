public protocol MigrationUsecaseProtocol {
    /// 이 사용자에게 아직 하지 않은 마이그레이션을 실행한다.
    ///
    /// 성공한 마이그레이션만 기록하므로, 실패하면 다음 실행 때 다시 한다.
    /// - Parameter userUuid: 로그인한 사용자 고유값
    func runPendingMigrations(userUuid: String) async throws
}
