public final class MigrationUsecaseImpl: MigrationUsecaseProtocol {
    private let migrationRepository: MigrationRepositoryProtocol

    public init(migrationRepository: MigrationRepositoryProtocol) {
        self.migrationRepository = migrationRepository
    }

    public func runPendingMigrations(userUuid: String) async throws {
        // 가입 OS 채우기: V2 가입이 가입 OS를 보내기 전에 가입한 사용자의 빈 값을 채운다.
        guard !migrationRepository.isSignupOsFilled(userUuid: userUuid) else { return }
        try await migrationRepository.fillSignupOs()
        migrationRepository.markSignupOsFilled(userUuid: userUuid)
    }
}
