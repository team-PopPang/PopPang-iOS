public final class ServerHealthUsecaseImpl: ServerHealthUsecaseProtocol {
    private let serverHealthRepository: ServerHealthRepositoryProtocol

    public init(serverHealthRepository: ServerHealthRepositoryProtocol) {
        self.serverHealthRepository = serverHealthRepository
    }

    public func checkHealth() async -> ServerHealth {
        await serverHealthRepository.checkHealth()
    }
}
