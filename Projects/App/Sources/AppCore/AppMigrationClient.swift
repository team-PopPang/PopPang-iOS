import ComposableArchitecture
import Core
import Domain

/// 메인 화면에 들어갈 때 이미 가입한 사용자의 서버 데이터를 한 번 보정하는 TCA 의존성
struct AppMigrationClient: Sendable {
    /// 실패해도 화면에는 알리지 않는다. 마치지 못한 마이그레이션은 다음 실행 때 다시 한다.
    var run: @Sendable (_ userUuid: String) async -> Void
}

extension AppMigrationClient {
    static func live(
        migrationUsecase: MigrationUsecaseProtocol
    ) -> Self {
        let migrationUsecaseBox = MigrationUsecaseBox(migrationUsecase)

        return Self(
            run: { userUuid in
                do {
                    try await migrationUsecaseBox.usecase.runPendingMigrations(userUuid: userUuid)
                } catch {
                    Logger.w("마이그레이션 실패, 다음 실행 때 다시 시도: \(error.localizedDescription)")
                }
            }
        )
    }
}

extension AppMigrationClient: DependencyKey {
    /// `AppBootstrap`에서 주입하지 않으면 아무것도 하지 않는다. 보정은 화면 동작에 영향을 주지 않기 때문이다.
    static let liveValue = AppMigrationClient(
        run: { _ in }
    )
}

extension DependencyValues {
    var appMigrationClient: AppMigrationClient {
        get { self[AppMigrationClient.self] }
        set { self[AppMigrationClient.self] = newValue }
    }
}

private final class MigrationUsecaseBox: @unchecked Sendable {
    let usecase: MigrationUsecaseProtocol

    init(_ usecase: MigrationUsecaseProtocol) {
        self.usecase = usecase
    }
}
