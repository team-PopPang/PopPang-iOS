import Domain
import Foundation

public struct ServerHealthDTO: Decodable, Hashable, Sendable {
    public let isHealthy: Bool

    public init(isHealthy: Bool) {
        self.isHealthy = isHealthy
    }

    func toEntity() -> ServerHealth {
        isHealthy ? .healthy : .unhealthy
    }
}
