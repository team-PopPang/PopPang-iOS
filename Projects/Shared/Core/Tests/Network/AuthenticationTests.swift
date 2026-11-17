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
        let storage = AuthTokenStorage(store: InMemoryStore())
        let plugin = AuthenticationPlugin(storage: storage, refresher: makeRefresher(storage: storage))
        let request = URLRequest(url: NetworkConfig.apiBaseURL(for: .v2))

        #expect(plugin.prepare(request, target: AuthTestAPI.access).authorizationHeader == nil)
        #expect(plugin.prepare(request, target: AuthTestAPI.signup).authorizationHeader == nil)
    }

    // MARK: - hostAccessToken (네트워크 밖에서 쓰는 Access Token)

    @Test("요청 전에는 저장된 Access Token을 그대로 돌려주고 갱신하지 않는다")
    func hostAccessTokenReturnsStoredToken() async throws {
        let storage = try makeStorage()
        let counter = CallCounter()
        let plugin = AuthenticationPlugin(storage: storage, refresher: makeRefresher(storage: storage, counter: counter))

        #expect(await plugin.hostAccessToken(rejected: nil, expired: false) == .accessToken("old-access"))
        #expect(await counter.count == 0)
    }

    @Test("401 5002를 받은 토큰을 넘기면 그 토큰을 만료된 토큰으로 갱신한다")
    func hostAccessTokenRefreshesExpiredToken() async throws {
        let storage = try makeStorage()
        let counter = CallCounter()
        let plugin = AuthenticationPlugin(storage: storage, refresher: makeRefresher(storage: storage, counter: counter))

        #expect(await plugin.hostAccessToken(rejected: "old-access", expired: true) == .accessToken("new-access"))
        #expect(await counter.refreshTokens == ["old-refresh"])
    }

    @Test("같은 토큰으로 보낸 요청 여러 개가 동시에 5002를 받아도 한 번만 갱신한다")
    func hostAccessTokenRefreshesOnceForSameExpiredToken() async throws {
        let storage = try makeStorage()
        let counter = CallCounter()
        let refresher = AccessTokenRefresher(storage: storage) { refreshToken in
            await counter.increment(refreshToken)
            try await ContinuousClock().sleep(for: .milliseconds(50))
            return .newTokens
        }
        let plugin = AuthenticationPlugin(storage: storage, refresher: refresher)

        let results = await withTaskGroup(of: HostAccessTokenResult.self) { group in
            for _ in 0..<3 {
                group.addTask { await plugin.hostAccessToken(rejected: "old-access", expired: true) }
            }
            return await group.reduce(into: [HostAccessTokenResult]()) { $0.append($1) }
        }

        #expect(results == Array(repeating: .accessToken("new-access"), count: 3))
        #expect(await counter.refreshTokens == ["old-refresh"])
    }

    @Test("만료가 아닌 401인데 그사이 다른 요청이 이미 로그아웃시켰으면 다시 알리지 않는다")
    func hostAccessTokenDoesNotNotifyTwiceWhenAlreadyLoggedOut() async throws {
        let storage = AuthTokenStorage(store: InMemoryStore())
        let events = AuthSessionEvents()
        let stream = events.loginRequired()
        let counter = CallCounter()
        let plugin = AuthenticationPlugin(
            storage: storage,
            refresher: makeRefresher(storage: storage, counter: counter),
            sessionEvents: events
        )

        #expect(await plugin.hostAccessToken(rejected: "old-access", expired: false) == .loginRequired)
        #expect(await counter.count == 0)
        #expect(try await receivesLoginRequired(stream) == false)
    }

    /// 지금까지 로그인 필요 알림이 왔는지 본다. `notifyLoginRequired`는 hostAccessToken 안에서 동기로 불리고 stream에 쌓이므로,
    /// 호출이 끝난 뒤에는 늦게 오는 알림이 없다. 쌓인 값이 있으면 바로 읽히고, 없으면 잠깐 뒤 취소해 `false`가 된다.
    private func receivesLoginRequired(_ stream: AsyncStream<Void>) async throws -> Bool {
        let notified = _Concurrency.Task {
            var iterator = stream.makeAsyncIterator()
            return await iterator.next() != nil
        }
        try await ContinuousClock().sleep(for: .milliseconds(50))
        notified.cancel()
        return await notified.value
    }

    @Test("새 토큰으로 보낸 요청이 다시 5002를 받으면 그 토큰으로 다시 갱신한다")
    func hostAccessTokenRefreshesAgainForNewExpiredToken() async throws {
        let storage = try makeStorage()
        try storage.saveTokens(.newTokens)
        let counter = CallCounter()
        let plugin = AuthenticationPlugin(storage: storage, refresher: makeRefresher(storage: storage, counter: counter))

        #expect(await plugin.hostAccessToken(rejected: "new-access", expired: true) == .accessToken("new-access"))
        #expect(await counter.refreshTokens == ["new-refresh"])
    }

    @Test("만료가 아닌 401이고 그 토큰이 아직 저장돼 있으면 토큰을 지우고 다시 로그인하라고 알린다")
    func hostAccessTokenLogsOutForRejectedCurrentToken() async throws {
        let storage = try makeStorage()
        let events = AuthSessionEvents()
        let stream = events.loginRequired()
        let counter = CallCounter()
        let plugin = AuthenticationPlugin(
            storage: storage,
            refresher: makeRefresher(storage: storage, counter: counter),
            sessionEvents: events
        )

        #expect(await plugin.hostAccessToken(rejected: "old-access", expired: false) == .loginRequired)
        #expect(storage.loadTokens() == nil)
        #expect(await counter.count == 0)
        var iterator = stream.makeAsyncIterator()
        #expect(await iterator.next() != nil)
    }

    @Test("만료가 아닌 401이어도 그사이 토큰이 바뀌었으면 새 토큰을 돌려준다")
    func hostAccessTokenReturnsNewTokenWhenRejectedTokenIsStale() async throws {
        let storage = try makeStorage()
        try storage.saveTokens(.newTokens)
        let counter = CallCounter()
        let plugin = AuthenticationPlugin(storage: storage, refresher: makeRefresher(storage: storage, counter: counter))

        #expect(await plugin.hostAccessToken(rejected: "old-access", expired: false) == .accessToken("new-access"))
        #expect(storage.loadTokens() == .newTokens)
        #expect(await counter.count == 0)
    }

    @Test("요청 전인데 토큰 쌍이 없으면 토큰을 건드리거나 알리지 않고 로그인 필요로 답한다")
    func hostAccessTokenRequiresLoginWhenLoggedOut() async throws {
        let storage = AuthTokenStorage(store: InMemoryStore())
        let events = AuthSessionEvents()
        let stream = events.loginRequired()
        let counter = CallCounter()
        let plugin = AuthenticationPlugin(
            storage: storage,
            refresher: makeRefresher(storage: storage, counter: counter),
            sessionEvents: events
        )

        #expect(await plugin.hostAccessToken(rejected: nil, expired: false) == .loginRequired)
        #expect(await counter.count == 0)
        #expect(try await receivesLoginRequired(stream) == false)
    }

    @Test("5002를 받았는데 그사이 다른 요청이 토큰을 지웠으면 갱신하지 않고 다시 알리지 않는다")
    func hostAccessTokenSkipsRefreshWhenAlreadyLoggedOut() async throws {
        let storage = AuthTokenStorage(store: InMemoryStore())
        let events = AuthSessionEvents()
        let stream = events.loginRequired()
        let counter = CallCounter()
        let plugin = AuthenticationPlugin(
            storage: storage,
            refresher: makeRefresher(storage: storage, counter: counter),
            sessionEvents: events
        )

        #expect(await plugin.hostAccessToken(rejected: "old-access", expired: true) == .loginRequired)
        #expect(await counter.count == 0)
        #expect(try await receivesLoginRequired(stream) == false)
    }

    @Test("갱신도 401이면 다시 로그인하라고 알린다")
    func hostAccessTokenNotifiesLoginRequiredWhenRefreshIsUnauthorized() async throws {
        let storage = try makeStorage()
        let events = AuthSessionEvents()
        let stream = events.loginRequired()
        let refresher = AccessTokenRefresher(storage: storage) { _ in
            throw NetworkError.invalidStatusCode(401, message: errorBody(code: 5007))
        }
        let plugin = AuthenticationPlugin(storage: storage, refresher: refresher, sessionEvents: events)

        #expect(await plugin.hostAccessToken(rejected: "old-access", expired: true) == .loginRequired)
        var iterator = stream.makeAsyncIterator()
        #expect(await iterator.next() != nil)
    }

    @Test("갱신이 401이 아닌 이유로 실패하면 일시 실패로 답하고 토큰은 그대로 둔다")
    func hostAccessTokenReportsTemporaryFailure() async throws {
        let storage = try makeStorage()
        let refresher = AccessTokenRefresher(storage: storage) { _ in
            throw NetworkError.invalidStatusCode(503, message: errorBody(code: 5013))
        }
        let plugin = AuthenticationPlugin(storage: storage, refresher: refresher)

        #expect(await plugin.hostAccessToken(rejected: "old-access", expired: true) == .temporaryFailure)
        #expect(storage.loadTokens() == .oldTokens)
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
        let store = InMemoryStore()
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

    @Test("만료된 토큰을 알 수 없으면 저장된 토큰이 있어도 갱신한다")
    func refreshesWhenExpiredTokenIsUnknown() async throws {
        let storage = try makeStorage()
        let counter = CallCounter()
        let refresher = makeRefresher(storage: storage, counter: counter)

        let accessToken = try await refresher.refreshAccessToken(expired: nil)

        #expect(accessToken == "new-access")
        #expect(await counter.count == 1)
    }

    @Test("Refresh Token이 없으면 다시 로그인해야 한다고 알린다")
    func requiresLoginWithoutRefreshToken() async {
        let storage = AuthTokenStorage(store: InMemoryStore())
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

    @Test("보낸 뒤에 다른 요청이 토큰을 갱신했으면 옛 토큰의 401로 새 토큰을 지우지 않고 새 토큰으로 다시 보낸다")
    func retriesWithRefreshedTokenWhenStaleRequestFails() async throws {
        let context = try RequestContext(responses: [
            (401, errorBody(code: 5001)),
            (200, #"{"message":"ok"}"#),
        ]) { storage in
            try? storage.saveTokens(.newTokens)
        }

        let response = try await context.provider.asyncRequest(.access, decodeTo: AuthTestResponse.self)

        #expect(response.message == "ok")
        #expect(context.responses.authorizationHeaders == ["Bearer old-access", "Bearer new-access"])
        #expect(context.storage.loadTokens() == .newTokens)
        #expect(await context.counter.count == 0)
    }

    @Test("새 토큰으로 다시 보낸 요청도 401을 받으면 더 다시 보내지 않는다")
    func doesNotRetryStaleRequestTwice() async throws {
        let context = try RequestContext(responses: [
            (401, errorBody(code: 5001)),
            (401, errorBody(code: 5002)),
        ]) { storage in
            try? storage.saveTokens(.newTokens)
        }

        await #expect(throws: NetworkError.invalidStatusCode(401, message: errorBody(code: 5002))) {
            _ = try await context.provider.asyncRequest(.access)
        }
        #expect(context.responses.authorizationHeaders.count == 2)
        #expect(await context.counter.count == 0)
    }

    @Test("Refresh Token만 남은 상태에서 토큰 없이 보낸 요청이 401을 받으면 남은 토큰을 지우고 다시 로그인해야 한다고 알린다")
    func clearsLoneRefreshTokenWhenRequestWithoutTokenFails() async throws {
        let store = InMemoryStore()
        let context = try RequestContext(store: store, responses: [(401, errorBody(code: 5006))])
        store.removeValue(forKey: AuthTokenStorage.Key.accessToken)

        await #expect(throws: AuthSessionError.loginRequired) {
            _ = try await context.provider.asyncRequest(.access)
        }
        #expect(context.responses.authorizationHeaders == [nil])
        #expect((store.value(forKey: AuthTokenStorage.Key.refreshToken) as String?) == nil)
    }

    @Test("토큰 없이 보낸 뒤 로그인으로 토큰이 생겼으면 새 토큰으로 한 번 다시 보낸다")
    func retriesWithLoginTokensWhenRequestWithoutTokenFails() async throws {
        let context = try RequestContext(responses: [
            (401, errorBody(code: 5006)),
            (200, #"{"message":"ok"}"#),
        ])
        context.storage.removeTokens()

        let provider = context.provider
        let storage = context.storage
        let responses = context.responses
        responses.setOnFirstSend { try? storage.saveTokens(.newTokens) }

        let response = try await provider.asyncRequest(.access, decodeTo: AuthTestResponse.self)

        #expect(response.message == "ok")
        #expect(responses.authorizationHeaders == [nil, "Bearer new-access"])
    }

    @Test("저장된 토큰이 하나도 없는데 401을 받으면 다시 로그인해야 한다고 알린다")
    func requiresLoginWhenRequestWithoutAnyTokenFails() async throws {
        let context = try RequestContext(responses: [(401, errorBody(code: 5006))])
        context.storage.removeTokens()

        await #expect(throws: AuthSessionError.loginRequired) {
            _ = try await context.provider.asyncRequest(.access)
        }
    }

    @Test("갱신이 401이 아닌 이유로 실패하면 원래 요청의 만료 오류를 던진다")
    func throwsOriginalErrorWhenRefreshFailsOtherwise() async throws {
        let context = try RequestContext(
            responses: [(401, errorBody(code: 5002))],
            refresh: { _ in throw NetworkError.invalidStatusCode(503, message: errorBody(code: 5013)) }
        )

        await #expect(throws: NetworkError.invalidStatusCode(401, message: errorBody(code: 5002))) {
            _ = try await context.provider.asyncRequest(.access)
        }
        #expect(context.storage.loadTokens() == .oldTokens)
    }

    @Test("다시 로그인해야 하면 구독한 곳 모두에 알린다")
    func notifiesAllSubscribersWhenLoginIsRequired() async throws {
        let events = AuthSessionEvents()
        let first = events.loginRequired()
        let second = events.loginRequired()
        let context = try RequestContext(responses: [(401, errorBody(code: 5001))], sessionEvents: events)

        await #expect(throws: AuthSessionError.loginRequired) {
            _ = try await context.provider.asyncRequest(.access)
        }

        var firstIterator = first.makeAsyncIterator()
        var secondIterator = second.makeAsyncIterator()
        #expect(await firstIterator.next() != nil)
        #expect(await secondIterator.next() != nil)
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

private func makeStorage(
    store: InMemoryStore = InMemoryStore(),
    signupToken: String? = nil
) throws -> AuthTokenStorage {
    let storage = AuthTokenStorage(store: store)
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

    func setOnFirstSend(_ hook: @escaping @Sendable () -> Void) {
        lock.withLock { onFirstSend = hook }
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

    /// - Parameter refresh: 갱신 API 대신 실행한다. `nil`이면 새 토큰 쌍을 돌려준다.
    init(
        store: InMemoryStore = InMemoryStore(),
        responses: [(Int, String)],
        onFirstSend: (@Sendable (AuthTokenStorage) -> Void)? = nil,
        refresh: AccessTokenRefresher.Refresh? = nil,
        sessionEvents: AuthSessionEvents? = nil
    ) throws {
        let storage = try makeStorage(store: store, signupToken: "signup")
        let stubResponses = StubResponses(responses, onFirstSend: onFirstSend.map { hook in { @Sendable in hook(storage) } })
        let counter = CallCounter()
        let refresher = refresh.map { AccessTokenRefresher(storage: storage, refresh: $0) }
            ?? makeRefresher(storage: storage, counter: counter)
        let authentication = AuthenticationPlugin(storage: storage, refresher: refresher, sessionEvents: sessionEvents)

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
