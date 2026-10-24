import Foundation
import Moya

public final class NetworkProvider: @unchecked Sendable {
    public static let shared = NetworkProvider()

    private let stubClosure: MoyaProvider<MultiTarget>.StubClosure
    private let plugins: [PluginType]
    private let trackInflights: Bool
    private let lock = NSLock()
    private var authentication: AuthenticationPlugin?

    /// - Parameter authentication: V2 인증 헤더와 Access Token 갱신을 맡는다. `nil`이면 어떤 요청에도 `Authorization` 헤더를 붙이지 않는다.
    public init(
        stubClosure: @escaping MoyaProvider<MultiTarget>.StubClosure = MoyaProvider.neverStub,
        plugins: [PluginType] = [],
        authentication: AuthenticationPlugin? = nil,
        trackInflights: Bool = false
    ) {
        self.stubClosure = stubClosure
        self.plugins = plugins
        self.authentication = authentication
        self.trackInflights = trackInflights
    }

    /// 인증을 설정한다. 앱 시작 때 `AppBootstrap`이 요청을 보내기 전에 한 번 부른다.
    /// 이미 만든 provider에는 적용되지 않으므로, Repository는 요청할 때마다 provider를 만든다.
    public func configureAuthentication(_ authentication: AuthenticationPlugin) {
        lock.withLock { self.authentication = authentication }
    }

    public func makeProvider<T: TargetType>(
        endpointClosure: @escaping (T) -> Endpoint = MoyaProvider.defaultEndpointMapping,
        plugins additionalPlugins: [PluginType] = []
    ) -> MoyaProvider<T> {
        let authentication = lock.withLock { self.authentication }
        return MoyaProvider<T>(
            endpointClosure: endpointClosure,
            stubClosure: { target in
                self.stubClosure(MultiTarget(target))
            },
            plugins: plugins + [authentication].compactMap { $0 } + additionalPlugins,
            trackInflights: trackInflights
        )
    }
}
