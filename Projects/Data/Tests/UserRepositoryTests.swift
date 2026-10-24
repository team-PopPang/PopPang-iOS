import Core
import Domain
import Foundation
import Moya
import Testing
@testable import Data

struct UserRepositoryTests {
    // MARK: - 요청 형식

    @Test("내 정보 API 4개는 V2 경로에 사용자 UUID 없이 Access Token을 쓴다")
    func requestsMatchV2Contract() throws {
        let check = try urlRequest(for: .checkNickname(nickname: "팝팡"))
        #expect(check.url?.path == "/api/v2/user/nickname/duplicated")
        #expect(URLComponents(url: try #require(check.url), resolvingAgainstBaseURL: false)?.queryItems == [URLQueryItem(name: "nickname", value: "팝팡")])
        #expect(check.httpMethod == "GET")

        let update = try urlRequest(for: .updateNickname(nickname: "새팝팡"))
        #expect(update.url?.path == "/api/v2/user")
        #expect(update.httpMethod == "PATCH")
        #expect(try jsonObject(update.httpBody) as? [String: String] == ["nickname": "새팝팡"])

        let alert = try urlRequest(for: .alertStatus(isAlerted: false))
        #expect(alert.url?.path == "/api/v2/user/alert-status")
        #expect(alert.httpMethod == "PATCH")
        #expect(try jsonObject(alert.httpBody) as? [String: Bool] == ["isAlerted": false])

        let withdraw = try urlRequest(for: .withdraw)
        #expect(withdraw.url?.path == "/api/v2/user")
        #expect(withdraw.httpMethod == "DELETE")
        #expect(withdraw.httpBody == nil)

        let targets: [V2UserAPI] = [.checkNickname(nickname: "팝팡"), .updateNickname(nickname: "새팝팡"), .alertStatus(isAlerted: true), .withdraw]
        #expect(targets.allSatisfy { $0.resolvedAuthorization == .access })
    }

    // MARK: - 응답

    @Test("닉네임 중복 확인은 APIResponse의 data에서 결과를 읽는다")
    func checkNicknameReadsWrappedResponse() async throws {
        let context = Context(response: (200, #"{"success":true,"code":0,"message":"요청 성공!","data":{"isDuplicated":true}}"#))

        #expect(try await context.repository.checkNickname(nickname: "팝팡") == true)
    }

    @Test("알림 설정 변경은 서버에 저장된 알림 상태를 돌려준다")
    func alertStatusReturnsSavedValue() async throws {
        let context = Context(response: (200, #"{"success":true,"code":0,"message":"요청 성공!","data":{"userUuid":"user-1","isAlerted":false}}"#))

        #expect(try await context.repository.alertStatus(isAlerted: false) == false)
    }

    @Test("닉네임 변경은 빈 본문을 성공으로 처리한다")
    func updateNicknameAcceptsEmptyBody() async throws {
        let context = Context(response: (200, ""))

        try await context.repository.updateNickname(newNickname: "새팝팡")
    }

    @Test("탈퇴에 성공하면 기기의 토큰을 지운다")
    func withdrawClearsTokens() async throws {
        let context = Context(response: (200, ""))

        try await context.repository.withdraw()

        #expect(context.storage.loadTokens() == nil)
    }

    @Test("탈퇴에 실패하면 토큰을 그대로 둔다")
    func failedWithdrawKeepsTokens() async throws {
        let context = Context(response: (500, error(6000)))

        await #expect(throws: UserError.failed) {
            try await context.repository.withdraw()
        }
        #expect(context.storage.loadTokens() == Context.tokens)
    }

    @Test(
        "닉네임 변경 실패 코드를 화면이 안내할 오류로 바꾼다",
        arguments: [
            (409, 4202, UserError.duplicateNickname),
            (400, 4205, .invalidNickname),
            (500, 6000, .failed),
        ]
    )
    func updateNicknameMapsErrors(statusCode: Int, code: Int, expected: UserError) async throws {
        let context = Context(response: (statusCode, error(code)))

        await #expect(throws: expected) {
            try await context.repository.updateNickname(newNickname: "새팝팡")
        }
    }
}

private func urlRequest(for target: V2UserAPI) throws -> URLRequest {
    try MoyaProvider<V2UserAPI>.defaultEndpointMapping(for: target).urlRequest()
}

private func jsonObject(_ data: Data?) throws -> Any {
    try JSONSerialization.jsonObject(with: try #require(data))
}

private func error(_ code: Int) -> String {
    #"{"success":false,"code":\#(code),"message":"error","data":null}"#
}

/// 로그인한 상태의 토큰 저장소와, 정해 둔 응답 하나를 돌려주는 Repository
private struct Context {
    static let tokens = AuthTokens(accessToken: "access", refreshToken: "refresh")

    let storage: AuthTokenStorage
    let repository: UserRepositoryImpl

    init(response: (Int, String)) {
        let storage = AuthTokenStorage(store: InMemoryStore())
        try? storage.saveTokens(Self.tokens)
        let networkProvider = NetworkProvider(stubClosure: MoyaProvider.immediatelyStub)

        self.storage = storage
        self.repository = UserRepositoryImpl(
            tokenStorage: storage,
            makeV2Provider: {
                networkProvider.makeProvider(
                    endpointClosure: { target in
                        Endpoint(
                            url: target.baseURL.appendingPathComponent(target.path).absoluteString,
                            sampleResponseClosure: { .networkResponse(response.0, Data(response.1.utf8)) },
                            method: target.method,
                            task: target.task,
                            httpHeaderFields: target.headers
                        )
                    }
                )
            }
        )
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
