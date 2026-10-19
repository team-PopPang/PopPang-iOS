import Foundation
import Moya

public final class NetworkProvider: @unchecked Sendable {
    public static let shared = NetworkProvider()

    private let stubClosure: MoyaProvider<MultiTarget>.StubClosure
    private let plugins: [PluginType]
    private let trackInflights: Bool

    /// - Parameter authentication: V2 인증 헤더와 Access Token 갱신을 맡는다. `nil`이면 어떤 요청에도 `Authorization` 헤더를 붙이지 않는다.
    public init(
        stubClosure: @escaping MoyaProvider<MultiTarget>.StubClosure = MoyaProvider.neverStub,
        plugins: [PluginType] = [],
        authentication: AuthenticationPlugin? = nil,
        trackInflights: Bool = false
    ) {
        self.stubClosure = stubClosure
        self.plugins = plugins + [authentication].compactMap { $0 }
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
