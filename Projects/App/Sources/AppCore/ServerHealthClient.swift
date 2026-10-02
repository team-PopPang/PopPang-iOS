import ComposableArchitecture
import Domain

/// 앱 시작 시 서버 헬스 체크를 요청하는 TCA 의존성
struct ServerHealthClient: Sendable {
    var check: @Sendable () async -> ServerHealth
}

extension ServerHealthClient {
    static func live(
        serverHealthUsecase: ServerHealthUsecaseProtocol
    ) -> Self {
        let serverHealthUsecaseBox = ServerHealthUsecaseBox(serverHealthUsecase)

        return Self(
            check: {
                await serverHealthUsecaseBox.usecase.checkHealth()
            }
        )
    }
}

extension ServerHealthClient: DependencyKey {
    /// `AppBootstrap`에서 주입하지 않으면 항상 점검 화면이 떠서 누락이 바로 드러난다.
    static let liveValue = ServerHealthClient(
        check: { .unhealthy }
    )
}

extension DependencyValues {
    var serverHealthClient: ServerHealthClient {
        get { self[ServerHealthClient.self] }
        set { self[ServerHealthClient.self] = newValue }
    }
}

private final class ServerHealthUsecaseBox: @unchecked Sendable {
    let usecase: ServerHealthUsecaseProtocol

    init(_ usecase: ServerHealthUsecaseProtocol) {
        self.usecase = usecase
    }
}
