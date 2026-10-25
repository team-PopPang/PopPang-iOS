public final class MigrationUsecaseImpl: MigrationUsecaseProtocol {
    private let migrationRepository: MigrationRepositoryProtocol

    public init(migrationRepository: MigrationRepositoryProtocol) {
        self.migrationRepository = migrationRepository
    }

    public func runPendingMigrations(userUuid: String) async throws {
        // 가입 OS 채우기: V2 가입이 가입 OS를 보내기 전에 가입한 사용자의 빈 값을 채운다.
        guard !migrationRepository.isSignupOsFilled(userUuid: userUuid) else { return }
        try Task.checkCancellation()
        try await migrationRepository.fillSignupOs()
        // 기다리는 동안 로그아웃해 취소됐으면 요청이 이 사용자의 토큰으로 처리됐는지 알 수 없어 기록하지 않는다.
        try Task.checkCancellation()
        migrationRepository.markSignupOsFilled(userUuid: userUuid)
    }
}
