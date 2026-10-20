import Core
import Domain
import Foundation
import Moya
import Testing
@testable import Data

/// 가짜 응답의 정적 상태를 공유하므로 테스트를 순서대로 실행한다.
@Suite(.serialized)
struct AuthRepositoryTests {
    // MARK: - 요청 형식

    @Test(
        "제공자마다 V2 로그인 경로와 본문 키가 맞고 인증 헤더 종류가 없다",
        arguments: [
            (SocialCredential.kakao(accessToken: "kakao-token"), "/api/v2/auth/kakao/mobile/login", ["access_token": "kakao-token"]),
            (.google(idToken: "google-token"), "/api/v2/auth/google/mobile/login", ["id_token": "google-token"]),
            (.apple(authCode: "code", rawNonce: "nonce"), "/api/v2/auth/apple/mobile/login", ["auth_code": "code", "raw_nonce": "nonce"]),
        ]
    )
    func loginRequestsMatchV2Contract(credential: SocialCredential, path: String, body: [String: String]) throws {
        let request = try urlRequest(for: .login(credential))

        #expect(request.url?.path == path)
        #expect(request.httpMethod == "POST")
        #expect(try jsonObject(request.httpBody) as? [String: String] == body)
        #expect(AuthAPI.login(credential).resolvedAuthorization == .none)
    }

    @Test("가입 요청은 가입 전용 토큰을 쓰고, 사용자 식별값 없이 다섯 키만 보낸다")
    func signupRequestMatchesV2Contract() throws {
        let signup = AuthAPI.signup(provider: .apple, request: V2SignupRequestDTO(.sample))
        let request = try urlRequest(for: signup)
        let body = try #require(try jsonObject(request.httpBody) as? [String: Any])

        #expect(request.url?.path == "/api/v2/auth/apple/signup")
        #expect(signup.resolvedAuthorization == .signup)
        #expect(Set(body.keys) == ["nickname", "isAlerted", "fcmToken", "alertKeywordList", "recommendList"])
        #expect(body["nickname"] as? String == "팝팡")
        #expect(body["recommendList"] as? [Int] == [1, 2])
    }

    @Test("내 정보 조회·로그아웃·토큰 갱신의 경로와 인증 종류가 맞다")
    func otherRequestsMatchV2Contract() throws {
        #expect(try urlRequest(for: .me).url?.path == "/api/v2/user")
        #expect(try urlRequest(for: .me).httpMethod == "GET")
        #expect(AuthAPI.me.resolvedAuthorization == .access)

        let logout = try urlRequest(for: .logout(accessToken: "access"))
        #expect(logout.url?.path == "/api/v2/auth/logout")
        #expect(logout.value(forHTTPHeaderField: "Authorization") == "Bearer access")
        #expect(AuthAPI.logout(accessToken: "access").resolvedAuthorization == .none)

        let refresh = try MoyaProvider<AuthTokenRefreshAPI>
            .defaultEndpointMapping(for: .refresh(refreshToken: "refresh"))
            .urlRequest()
        #expect(refresh.url?.path == "/api/v2/auth/refresh")
        #expect(try jsonObject(refresh.httpBody) as? [String: String] == ["refreshToken": "refresh"])
        #expect(AuthTokenRefreshAPI.refresh(refreshToken: "refresh").resolvedAuthorization == .none)
    }

    @Test("애플 nonce는 원문과 다르게 SHA-256 소문자 16진수로 바뀐다")
    func appleNonceIsHashedAsLowercaseHex() throws {
        let rawNonce = try AppleLoginStrategy.makeRawNonce()

        #expect(rawNonce.count == 64)
        #expect(try AppleLoginStrategy.makeRawNonce() != rawNonce)
        #expect(AppleLoginStrategy.sha256("abc") == "ba7816bf8f01cfea414140de5dae2223b00361a396177a9cb410ff61f20015ad")
    }

    // MARK: - 로그인

    @Test("가입을 마친 사용자는 토큰 쌍을 저장하고 사용자를 돌려준다")
    func completedLoginSavesTokens() async throws {
        let context = Context(responses: [(200, Fixture.completed)])

        let result = try await context.repository.login(with: .kakao)

        guard case let .completed(user) = result else {
            Issue.record("COMPLETED가 아니에요: \(result)")
            return
        }
        #expect(user.userUuid == "0b6e1f3a-5c2d-4e8f-9a1b-2c3d4e5f6a7b")
        #expect(user.nickname == "팝팡")
        #expect(context.storage.loadTokens() == AuthTokens(accessToken: "access", refreshToken: "refresh"))
        #expect(context.storage.loadSignupToken() == nil)
    }

    @Test("가입이 필요한 사용자는 가입 전용 토큰만 저장한다")
    func pendingLoginSavesSignupToken() async throws {
        let context = Context(responses: [(200, Fixture.pending)])

        let result = try await context.repository.login(with: .google)

        #expect(result == .pending(.google))
        #expect(context.storage.loadSignupToken() == "signup")
        #expect(context.storage.loadTokens() == nil)
    }

    @Test(
        "로그인 실패 코드를 화면이 안내할 오류로 바꾼다",
        arguments: [
            (401, 5010, AuthError.inactiveAccount),
            (409, 5016, .socialAccountConflict),
            (401, 5015, .failed),
            (429, 5018, .failed),
        ]
    )
    func mapsLoginErrors(statusCode: Int, code: Int, expected: AuthError) async {
        let context = Context(responses: [(statusCode, Fixture.error(code))])

        await #expect(throws: expected) {
            _ = try await context.repository.login(with: .kakao)
        }
    }

    @Test("사용자가 소셜 로그인 창을 닫으면 서버에 요청하지 않는다")
    func cancelledSocialLoginDoesNotCallServer() async {
        let context = Context(responses: [], strategyError: AuthError.cancelled)

        await #expect(throws: AuthError.cancelled) {
            _ = try await context.repository.login(with: .kakao)
        }
        #expect(context.stub.requestCount == 0)
    }

    // MARK: - 가입

    @Test("가입에 성공하면 토큰 쌍을 저장하고 가입 전용 토큰을 지운다")
    func signupSavesTokensAndRemovesSignupToken() async throws {
        let context = Context(responses: [(200, Fixture.completed)])
        try context.storage.saveSignupToken("signup")

        let user = try await context.repository.signup(with: .kakao, request: .sample)

        #expect(user.nickname == "팝팡")
        #expect(context.storage.loadTokens() == AuthTokens(accessToken: "access", refreshToken: "refresh"))
        #expect(context.storage.loadSignupToken() == nil)
    }

    @Test("가입 전용 토큰이 없으면 요청하지 않고 소셜 로그인부터 다시 하게 한다")
    func signupWithoutSignupTokenRequiresLogin() async {
        let context = Context(responses: [])

        await #expect(throws: AuthError.signupSessionExpired) {
            _ = try await context.repository.signup(with: .kakao, request: .sample)
        }
        #expect(context.stub.requestCount == 0)
    }

    @Test(
        "가입 실패 코드를 화면이 안내할 오류로 바꾸고, 가입 단계가 끝났으면 가입 전용 토큰을 지운다",
        arguments: [
            (409, 4202, AuthError.duplicateNickname),
            (400, 5017, .invalidSignupRequest),
            (400, 4304, .invalidSignupRequest),
            (401, 5002, .signupSessionExpired),
            (401, 5014, .signupSessionExpired),
            (409, 4204, .signupSessionExpired),
            (403, 5012, .signupSessionExpired),
        ]
    )
    func mapsSignupErrors(statusCode: Int, code: Int, expected: AuthError) async throws {
        let context = Context(responses: [(statusCode, Fixture.error(code))])
        try context.storage.saveSignupToken("signup")

        await #expect(throws: expected) {
            _ = try await context.repository.signup(with: .kakao, request: .sample)
        }
        let isSignupTokenKept = context.storage.loadSignupToken() != nil
        #expect(isSignupTokenKept == (expected != .signupSessionExpired))
    }

    // MARK: - 세션 복구와 로그아웃

    @Test("저장된 토큰이 없으면 서버에 묻지 않고 로그인 상태가 아니라고 돌려준다")
    func restoreSessionWithoutTokensReturnsNil() async throws {
        let context = Context(responses: [])
        try context.storage.saveSignupToken("signup")

        #expect(try await context.repository.restoreSession() == nil)
        #expect(context.stub.requestCount == 0)
        #expect(context.storage.loadSignupToken() == nil)
    }

    @Test("저장된 토큰으로 내 정보를 받아 로그인 상태를 되살린다")
    func restoreSessionFetchesUser() async throws {
        let context = Context(responses: [(200, Fixture.me)])
        try context.storage.saveTokens(AuthTokens(accessToken: "access", refreshToken: "refresh"))

        let user = try await context.repository.restoreSession()

        #expect(user?.userUuid == "0b6e1f3a-5c2d-4e8f-9a1b-2c3d4e5f6a7b")
        #expect(context.stub.authorizationHeaders == ["Bearer access"])
    }

    @Test("서버 오류로 내 정보를 받지 못하면 토큰을 지우지 않고 오류를 던진다")
    func restoreSessionKeepsTokensOnServerError() async throws {
        let context = Context(responses: [(500, Fixture.error(6000))])
        let tokens = AuthTokens(accessToken: "access", refreshToken: "refresh")
        try context.storage.saveTokens(tokens)

        await #expect(throws: NetworkError.self) {
            _ = try await context.repository.restoreSession()
        }
        #expect(context.storage.loadTokens() == tokens)
    }

    @Test("가입 응답이 COMPLETED가 아니면 가입 전용 토큰을 지우고 로그인부터 다시 하게 한다")
    func pendingSignupResponseRequiresLogin() async throws {
        let context = Context(responses: [(200, Fixture.pending)])
        try context.storage.saveSignupToken("old-signup")

        await #expect(throws: AuthError.signupSessionExpired) {
            _ = try await context.repository.signup(with: .kakao, request: .sample)
        }
        #expect(context.storage.loadSignupToken() == nil)
    }

    @Test("서버 로그아웃을 기다리는 동안 다시 로그인했으면 새 토큰은 지우지 않는다")
    func logoutKeepsTokensSavedDuringRequest() async throws {
        let context = Context(responses: [(200, "")]) { storage in
            try? storage.saveTokens(AuthTokens(accessToken: "new-access", refreshToken: "new-refresh"))
        }
        try context.storage.saveTokens(AuthTokens(accessToken: "access", refreshToken: "refresh"))

        await context.repository.logout()

        #expect(context.storage.loadTokens() == AuthTokens(accessToken: "new-access", refreshToken: "new-refresh"))
    }

    @Test("Access Token이 만료된 상태로 로그아웃해도 갱신하지 않고 기기의 토큰을 지운다")
    func logoutWithExpiredTokenDoesNotRefresh() async throws {
        let context = Context(responses: [(401, Fixture.error(5002))])
        try context.storage.saveTokens(AuthTokens(accessToken: "access", refreshToken: "refresh"))

        await context.repository.logout()

        #expect(context.stub.requestCount == 1)
        #expect(context.storage.loadTokens() == nil)
    }

    @Test("서버 로그아웃이 실패해도 기기의 토큰은 지운다")
    func logoutClearsTokensEvenIfServerFails() async throws {
        let context = Context(responses: [(503, Fixture.error(5013))])
        try context.storage.saveTokens(AuthTokens(accessToken: "access", refreshToken: "refresh"))

        await context.repository.logout()

        #expect(context.stub.authorizationHeaders == ["Bearer access"])
        #expect(context.storage.loadTokens() == nil)
    }
}

// MARK: - 테스트 도구

private enum Fixture {
    static let user = """
    {"userUuid":"0b6e1f3a-5c2d-4e8f-9a1b-2c3d4e5f6a7b","provider":"KAKAO","email":"user@example.com","nickname":"팝팡","role":"MEMBER","isAlerted":true}
    """

    static let completed = """
    {"success":true,"code":0,"message":"요청 성공!","data":{"signupStatus":"COMPLETED","tokenType":"Bearer","user":\(user),"accessToken":"access","refreshToken":"refresh","accessTokenExpiresIn":900,"refreshTokenExpiresIn":2592000}}
    """

    static let pending = """
    {"success":true,"code":0,"message":"요청 성공!","data":{"signupStatus":"PENDING","tokenType":"Bearer","signupToken":"signup","signupTokenExpiresIn":900}}
    """

    static let me = """
    {"success":true,"code":0,"message":"요청 성공!","data":\(user)}
    """

    static func error(_ code: Int) -> String {
        #"{"success":false,"code":\#(code),"message":"error","data":null}"#
    }
}

private extension SignupRequest {
    static let sample = SignupRequest(
        nickname: "팝팡",
        isAlerted: true,
        fcmToken: "fcm",
        alertKeywordList: ["전시"],
        recommendList: [1, 2]
    )
}

private func urlRequest(for target: AuthAPI) throws -> URLRequest {
    try MoyaProvider<AuthAPI>.defaultEndpointMapping(for: target).urlRequest()
}

private func jsonObject(_ data: Data?) throws -> Any {
    try JSONSerialization.jsonObject(with: try #require(data))
}

private struct FakeLoginStrategy: SocialLoginStrategy {
    let provider: Provider
    let error: AuthError?

    func login() async throws -> SocialCredential {
        if let error { throw error }
        switch provider {
        case .kakao:
            return .kakao(accessToken: "kakao-token")
        case .google:
            return .google(idToken: "google-token")
        case .apple:
            return .apple(authCode: "code", rawNonce: "nonce")
        }
    }
}

/// 메모리에 값을 두는 저장 수단
private final class InMemoryStore: Storing, @unchecked Sendable {
    private let lock = NSLock()
    private var values: [String: Any] = [:]

    func value<T>(forKey key: String) -> T? {
        lock.withLock { values[key] as? T }
    }

    func set<T>(_ value: T, forKey key: String) throws {
        lock.withLock { values[key] = value }
    }

    func removeValue(forKey key: String) {
        lock.withLock { _ = values.removeValue(forKey: key) }
    }
}

/// 요청 순서대로 정해 둔 응답을 돌려주고, 보낸 요청의 `Authorization` 헤더를 기록한다.
private final class StubResponses: PluginType, @unchecked Sendable {
    private let lock = NSLock()
    private var responses: [(Int, String)]
    private var headers: [String?] = []
    private var onFirstSend: (@Sendable () -> Void)?

    /// - Parameter onFirstSend: 첫 요청을 보낸 직후, 응답을 받기 전에 실행한다. 다른 동작이 끼어든 상황을 만든다.
    init(_ responses: [(Int, String)], onFirstSend: (@Sendable () -> Void)? = nil) {
        self.responses = responses
        self.onFirstSend = onFirstSend
    }

    var requestCount: Int {
        lock.withLock { headers.count }
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

private struct Context {
    let storage: AuthTokenStorage
    let stub: StubResponses
    let repository: AuthRepositoryImpl

    init(
        responses: [(Int, String)],
        strategyError: AuthError? = nil,
        onFirstSend: (@Sendable (AuthTokenStorage) -> Void)? = nil
    ) {
        let storage = AuthTokenStorage(store: InMemoryStore())
        let stub = StubResponses(responses, onFirstSend: onFirstSend.map { hook in { @Sendable in hook(storage) } })
        let authentication = AuthenticationPlugin(
            storage: storage,
            refresher: AccessTokenRefresher(storage: storage) { _ in
                throw NetworkError.invalidStatusCode(401, message: Fixture.error(5007))
            }
        )
        let networkProvider = NetworkProvider(
            stubClosure: MoyaProvider.immediatelyStub,
            authentication: authentication
        )

        self.storage = storage
        self.stub = stub
        self.repository = AuthRepositoryImpl(
            strategies: Provider.allCases.map { FakeLoginStrategy(provider: $0, error: strategyError) },
            tokenStorage: storage,
            makeProvider: {
                networkProvider.makeProvider(
                    endpointClosure: { target in
                        Endpoint(
                            url: target.baseURL.appendingPathComponent(target.path).absoluteString,
                            sampleResponseClosure: { stub.next() },
                            method: target.method,
                            task: target.task,
                            httpHeaderFields: target.headers
                        )
                    },
                    plugins: [stub]
                )
            }
        )
    }
}
