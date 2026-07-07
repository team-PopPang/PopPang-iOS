import Foundation
import Moya

public final class NetworkProvider: @unchecked Sendable {
    public static let shared = NetworkProvider()

    private let stubClosure: MoyaProvider<MultiTarget>.StubClosure
    private let plugins: [PluginType]
    private let trackInflights: Bool

    public init(
        stubClosure: @escaping MoyaProvider<MultiTarget>.StubClosure = MoyaProvider.neverStub,
        plugins: [PluginType] = [],
        trackInflights: Bool = false
    ) {
        self.stubClosure = stubClosure
        self.plugins = plugins
        self.trackInflights = trackInflights
    }

    public func makeProvider<T: TargetType>(
        endpointClosure: @escaping (T) -> Endpoint = MoyaProvider.defaultEndpointMapping,
        plugins additionalPlugins: [PluginType] = []
    ) -> MoyaProvider<T> {
        MoyaProvider<T>(
            endpointClosure: endpointClosure,
            stubClosure: { target in
                self.stubClosure(MultiTarget(target))
            },
            plugins: plugins + additionalPlugins,
            trackInflights: trackInflights
        )
    }
}
