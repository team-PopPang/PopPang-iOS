import Foundation
import Moya
import Testing
@testable import Core

struct AuthenticationTests {
    @Test("인증 종류에 맞는 토큰을 Bearer 헤더로 붙이고, V1과 공개 API에는 붙이지 않는다")
    func attachesBearerTokenByAuthorization() throws {
        let storage = try makeStorage(signupToken: "signup")
        let plugin = AuthenticationPlugin(storage: storage, refresher: makeRefresher(storage: storage))
        let request = URLRequest(url: NetworkConfig.apiBaseURL(for: .v2))

        #expect(plugin.prepare(request, target: AuthTestAPI.access).authorizationHeader == "Bearer old-access")
        #expect(plugin.prepare(request, target: MultiTarget(AuthTestAPI.access)).authorizationHeader == "Bearer old-access")
        #expect(plugin.prepare(request, target: AuthTestAPI.signup).authorizationHeader == "Bearer signup")
        #expect(plugin.prepare(request, target: AuthTestAPI.publicV2).authorizationHeader == nil)
        #expect(plugin.prepare(request, target: AuthTestAPI.v1Access).authorizationHeader == nil)
    }

    @Test("저장된 토큰이 없으면 헤더를 붙이지 않는다")
    func skipsHeaderWithoutToken() {
        let storage = AuthTokenStorage(store: InMemoryKeychainStore())
        let plugin = AuthenticationPlugin(storage: storage, refresher: makeRefresher(storage: storage))
        let request = URLRequest(url: NetworkConfig.apiBaseURL(for: .v2))

        #expect(plugin.prepare(request, target: AuthTestAPI.access).authorizationHeader == nil)
        #expect(plugin.prepare(request, target: AuthTestAPI.signup).authorizationHeader == nil)
    }

    // MARK: - AccessTokenRefresher

    @Test("동시에 만료돼도 갱신 요청은 한 번만 보내고 모두 새 토큰을 받는다")
    func refreshesOnceForConcurrentExpiry() async throws {
        let storage = try makeStorage()
        let counter = CallCounter()
        let refresher = AccessTokenRefresher(storage: storage) { refreshToken in
            await counter.increment(refreshToken)
            try await ContinuousClock().sleep(for: .milliseconds(50))
            return .newTokens
        }

        let accessTokens = try await withThrowingTaskGroup(of: String.self) { group in
            for _ in 0..<5 {
                group.addTask { try await refresher.refreshAccessToken(expired: "old-access") }
            }
            return try await group.reduce(into: [String]()) { $0.append($1) }
        }

        #expect(accessTokens == Array(repeating: "new-access", count: 5))
        #expect(await counter.refreshTokens == ["old-refresh"])
        #expect(storage.loadTokens() == .newTokens)
    }

    @Test("다른 요청이 이미 갱신했으면 다시 갱신하지 않는다")
    func skipsRefreshWhenAlreadyRefreshed() async throws {
        let storage = try makeStorage()
        try storage.saveTokens(.newTokens)
        let counter = CallCounter()
        let refresher = makeRefresher(storage: storage, counter: counter)

        let accessToken = try await refresher.refreshAccessToken(expired: "old-access")

        #expect(accessToken == "new-access")
        #expect(await counter.count == 0)
    }

    @Test("갱신 API가 401을 주면 토큰을 지우고 다시 로그인해야 한다고 알린다")
    func clearsTokensWhenRefreshIsUnauthorized() async throws {
        let storage = try makeStorage()
        let refresher = AccessTokenRefresher(storage: storage) { _ in
            throw NetworkError.invalidStatusCode(401, message: errorBody(code: 5007))
        }

        await #expect(throws: AuthSessionError.loginRequired) {
            _ = try await refresher.refreshAccessToken(expired: "old-access")
        }
        #expect(storage.loadTokens() == nil)
    }

    @Test(
        "갱신이 401이 아닌 이유로 실패하면 토큰을 그대로 두고 받은 오류를 던진다",
        arguments: [400, 403, 429, 500, 503]
    )
    func keepsTokensWhenRefreshFailsOtherwise(statusCode: Int) async throws {
        let storage = try makeStorage()
        let error = NetworkError.invalidStatusCode(statusCode, message: errorBody(code: 5013))
        let refresher = AccessTokenRefresher(storage: storage) { _ in throw error }

        await #expect(throws: error) {
            _ = try await refresher.refreshAccessToken(expired: "old-access")
        }
        #expect(storage.loadTokens() == .oldTokens)
    }

    @Test("갱신하는 동안 토큰이 지워지면 늦게 온 새 토큰을 저장하지 않는다")
    func discardsRefreshResultAfterTokensAreCleared() async throws {
        let storage = try makeStorage()
        let refresher = AccessTokenRefresher(storage: storage) { _ in
            storage.clear()
            return .newTokens
        }

        await #expect(throws: AuthSessionError.loginRequired) {
            _ = try await refresher.refreshAccessToken(expired: "old-access")
        }
        #expect(storage.loadTokens() == nil)
    }

    @Test("갱신하는 동안 다시 로그인했으면 늦게 온 응답 대신 새 로그인 토큰을 쓴다")
    func usesReloginTokensWhenRefreshSucceedsLate() async throws {
        let storage = try makeStorage()
        let refresher = AccessTokenRefresher(storage: storage) { _ in
            try storage.saveTokens(.reloginTokens)
            return .newTokens
        }

        let accessToken = try await refresher.refreshAccessToken(expired: "old-access")

        #expect(accessToken == "relogin-access")
        #expect(storage.loadTokens() == .reloginTokens)
    }

    @Test("갱신하는 동안 다시 로그인했으면 늦게 온 401이 새 로그인 토큰을 지우지 않는다")
    func keepsReloginTokensWhenRefreshFailsLate() async throws {
        let storage = try makeStorage()
        let refresher = AccessTokenRefresher(storage: storage) { _ in
            try storage.saveTokens(.reloginTokens)
            throw NetworkError.invalidStatusCode(401, message: errorBody(code: 5007))
        }

        let accessToken = try await refresher.refreshAccessToken(expired: "old-access")

        #expect(accessToken == "relogin-access")
        #expect(storage.loadTokens() == .reloginTokens)
    }

    @Test("갱신한 토큰을 저장하지 못하면 다시 로그인해야 한다고 알린다")
    func requiresLoginWhenSavingRefreshedTokensFails() async throws {
        let store = InMemoryKeychainStore()
        let storage = AuthTokenStorage(store: store)
        try storage.saveTokens(.oldTokens)
        let refresher = AccessTokenRefresher(storage: storage) { _ in
            store.failingKeys = [AuthTokenStorage.Key.refreshToken]
            return .newTokens
        }

        await #expect(throws: AuthSessionError.loginRequired) {
            _ = try await refresher.refreshAccessToken(expired: "old-access")
        }
        #expect(storage.loadTokens() == nil)
    }

    @Test("Refresh Token이 없으면 다시 로그인해야 한다고 알린다")
    func requiresLoginWithoutRefreshToken() async {
        let storage = AuthTokenStorage(store: InMemoryKeychainStore())
        let counter = CallCounter()
        let refresher = makeRefresher(storage: storage, counter: counter)

        await #expect(throws: AuthSessionError.loginRequired) {
            _ = try await refresher.refreshAccessToken(expired: nil)
        }
        #expect(await counter.count == 0)
    }

    // MARK: - 요청 재시도

    @Test("Access API가 만료 응답을 받으면 갱신한 뒤 새 토큰으로 한 번 다시 보낸다")
    func retriesOnceWithRefreshedToken() async throws {
        let context = try RequestContext(responses: [
            (401, errorBody(code: 5002)),
            (200, #"{"message":"ok"}"#),
        ])

        let response = try await context.provider.asyncRequest(.access, decodeTo: AuthTestResponse.self)

        #expect(response.message == "ok")
        #expect(context.responses.authorizationHeaders == ["Bearer old-access", "Bearer new-access"])
        #expect(await context.counter.count == 1)
        #expect(context.storage.loadTokens() == .newTokens)
    }

    @Test("다시 보낸 요청도 만료 응답을 받으면 더 갱신하지 않는다")
    func doesNotRetryTwice() async throws {
        let context = try RequestContext(responses: [
            (401, errorBody(code: 5002)),
            (401, errorBody(code: 5002)),
        ])

        await #expect(throws: NetworkError.invalidStatusCode(401, message: errorBody(code: 5002))) {
            _ = try await context.provider.asyncRequest(.access)
        }
        #expect(context.responses.authorizationHeaders.count == 2)
        #expect(await context.counter.count == 1)
    }

    @Test(
        "5002가 아닌 401을 받으면 갱신하지 않고 토큰을 지운다",
        arguments: [5001, 5003, 5004, 5005, 5006, 5010]
    )
    func clearsTokensForOtherUnauthorizedCodes(code: Int) async throws {
        let context = try RequestContext(responses: [(401, errorBody(code: code))])

        await #expect(throws: AuthSessionError.loginRequired) {
            _ = try await context.provider.asyncRequest(.access)
        }
        #expect(await context.counter.count == 0)
        #expect(context.storage.loadTokens() == nil)
    }

    @Test("보낸 뒤에 다른 요청이 토큰을 갱신했으면 옛 토큰의 401이 새 토큰을 지우지 않는다")
    func keepsRefreshedTokensWhenStaleRequestFails() async throws {
        let context = try RequestContext(responses: [(401, errorBody(code: 5001))]) { storage in
            try? storage.saveTokens(.newTokens)
        }

        await #expect(throws: NetworkError.invalidStatusCode(401, message: errorBody(code: 5001))) {
            _ = try await context.provider.asyncRequest(.access)
        }
        #expect(context.responses.authorizationHeaders == ["Bearer old-access"])
        #expect(context.storage.loadTokens() == .newTokens)
    }

    @Test("403에는 갱신하지 않고 토큰을 그대로 둔다")
    func doesNotRefreshForForbidden() async throws {
        let context = try RequestContext(responses: [(403, errorBody(code: 5008))])

        await #expect(throws: NetworkError.invalidStatusCode(403, message: errorBody(code: 5008))) {
            _ = try await context.provider.asyncRequest(.access)
        }
        #expect(await context.counter.count == 0)
        #expect(context.storage.loadTokens() == .oldTokens)
    }

    @Test(
        "회원가입 API와 V1 API는 만료 응답을 받아도 갱신하지 않는다",
        arguments: [AuthTestAPI.signup, .v1Access]
    )
    func doesNotRefreshForNonAccessTargets(target: AuthTestAPI) async throws {
        let context = try RequestContext(responses: [(401, errorBody(code: 5002))])

        await #expect(throws: NetworkError.invalidStatusCode(401, message: errorBody(code: 5002))) {
            _ = try await context.provider.asyncRequest(target)
        }
        #expect(await context.counter.count == 0)
        #expect(context.storage.loadTokens() == .oldTokens)
    }
}

// MARK: - 테스트 도구

private func errorBody(code: Int) -> String {
    #"{"success":false,"code":\#(code),"message":"error","data":null}"#
}

private func makeStorage(signupToken: String? = nil) throws -> AuthTokenStorage {
    let storage = AuthTokenStorage(store: InMemoryKeychainStore())
    try storage.saveTokens(.oldTokens)
    if let signupToken {
        try storage.saveSignupToken(signupToken)
    }
    return storage
}

private func makeRefresher(
    storage: AuthTokenStorage,
    counter: CallCounter = CallCounter()
) -> AccessTokenRefresher {
    AccessTokenRefresher(storage: storage) { refreshToken in
        await counter.increment(refreshToken)
        return .newTokens
    }
}

private extension AuthTokens {
    static let oldTokens = AuthTokens(accessToken: "old-access", refreshToken: "old-refresh")
    static let newTokens = AuthTokens(accessToken: "new-access", refreshToken: "new-refresh")
    static let reloginTokens = AuthTokens(accessToken: "relogin-access", refreshToken: "relogin-refresh")
}

private extension URLRequest {
    var authorizationHeader: String? {
        value(forHTTPHeaderField: "Authorization")
    }
}

private actor CallCounter {
    private(set) var refreshTokens: [String] = []

    var count: Int {
        refreshTokens.count
    }

    func increment(_ refreshToken: String) {
        refreshTokens.append(refreshToken)
    }
}

/// 요청 순서대로 정해 둔 응답을 돌려주고, 보낸 요청의 `Authorization` 헤더를 기록한다.
private final class StubResponses: PluginType, @unchecked Sendable {
    private let lock = NSLock()
    private var responses: [(Int, String)]
    private var headers: [String?] = []
    private var onFirstSend: (@Sendable () -> Void)?

    /// - Parameter onFirstSend: 첫 요청을 보낸 직후, 응답을 받기 전에 실행한다. 다른 요청이 끼어든 상황을 만든다.
    init(_ responses: [(Int, String)], onFirstSend: (@Sendable () -> Void)? = nil) {
        self.responses = responses
        self.onFirstSend = onFirstSend
    }

    var authorizationHeaders: [String?] {
        lock.withLock { headers }
    }

    func next() -> EndpointSampleResponse {
        lock.withLock {
            let (statusCode, body) = responses.isEmpty ? (500, "") : responses.removeFirst()
            return .networkResponse(statusCode, Data(body.utf8))
        }
    }

    func willSend(_ request: RequestType, target: TargetType) {
        let onFirstSend = lock.withLock {
            headers.append(request.request?.value(forHTTPHeaderField: "Authorization"))
            defer { self.onFirstSend = nil }
            return self.onFirstSend
        }
        onFirstSend?()
    }
}

private struct RequestContext {
    let storage: AuthTokenStorage
    let counter: CallCounter
    let responses: StubResponses
    let provider: MoyaProvider<AuthTestAPI>

    init(
        responses: [(Int, String)],
        onFirstSend: (@Sendable (AuthTokenStorage) -> Void)? = nil
    ) throws {
        let storage = try makeStorage(signupToken: "signup")
        let stubResponses = StubResponses(responses, onFirstSend: onFirstSend.map { hook in { hook(storage) } })
        let counter = CallCounter()
        let authentication = AuthenticationPlugin(
            storage: storage,
            refresher: makeRefresher(storage: storage, counter: counter)
        )

        self.storage = storage
        self.counter = counter
        self.responses = stubResponses
        self.provider = NetworkProvider(
            stubClosure: MoyaProvider.immediatelyStub,
            authentication: authentication
        ).makeProvider(
            endpointClosure: { target in
                Endpoint(
                    url: target.baseURL.appendingPathComponent(target.path).absoluteString,
                    sampleResponseClosure: { stubResponses.next() },
                    method: target.method,
                    task: target.task,
                    httpHeaderFields: target.headers
                )
            },
            plugins: [stubResponses]
        )
    }
}

enum AuthTestAPI: BaseAPI {
    case access
    case signup
    case publicV2
    case v1Access

    var apiVersion: APIVersion {
        self == .v1Access ? .v1 : .v2
    }

    var authorization: APIAuthorization {
        switch self {
        case .access, .v1Access:
            return .access
        case .signup:
            return .signup
        case .publicV2:
            return .none
        }
    }

    var path: String {
        "/auth-test"
    }

    var method: Moya.Method {
        .get
    }

    var task: Moya.Task {
        .requestPlain
    }

    var validationType: ValidationType {
        .none
    }
}

private struct AuthTestResponse: Decodable {
    let message: String
}
