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

    @Test("탈퇴는 빈 본문을 성공으로 처리하고, 기기의 토큰은 로그아웃 전환이 지우도록 남겨 둔다")
    func withdrawKeepsTokensForLogout() async throws {
        let context = Context(response: (200, ""))

        try await context.repository.withdraw()

        #expect(context.storage.loadTokens() == Context.tokens)
    }

    @Test("탈퇴를 다시 보내 사용자가 없다는 응답(404 4201)을 받으면 이미 탈퇴한 것으로 본다")
    func withdrawTreatsMissingUserAsWithdrawn() async throws {
        let context = Context(response: (404, error(4201)))

        try await context.repository.withdraw()
    }

    @Test("탈퇴가 서버 오류로 실패하면 화면이 안내할 실패를 던진다")
    func failedWithdrawThrowsUserError() async throws {
        let context = Context(response: (500, error(6000)))

        await #expect(throws: UserError.failed) {
            try await context.repository.withdraw()
        }
    }

    @Test("다시 로그인해야 하는 실패는 UserError로 바꾸지 않고 그대로 던진다")
    func loginRequiredIsRethrown() async throws {
        let context = Context(response: (401, error(5006)))

        await #expect(throws: AuthSessionError.loginRequired) {
            _ = try await context.repository.alertStatus(isAlerted: true)
        }
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

extension UserRepositoryTests {
    // MARK: - 알림 키워드

    @Test("알림 키워드 목록·등록·삭제는 V2 경로에 사용자 UUID 없이 Access Token으로 보내고, 등록·삭제는 본문에 keyword만 담는다")
    func alertKeywordRequestsMatchV2Contract() throws {
        let list = try MoyaProvider<V2AlertKeywordAPI>.defaultEndpointMapping(for: .list).urlRequest()
        #expect(list.url?.path == "/api/v2/alert-keyword")
        #expect(list.httpMethod == "GET")
        #expect(list.httpBody == nil)

        for (target, method) in [(V2AlertKeywordAPI.add(keyword: "캐릭터"), "POST"), (.remove(keyword: "캐릭터"), "DELETE")] {
            let request = try MoyaProvider<V2AlertKeywordAPI>.defaultEndpointMapping(for: target).urlRequest()
            #expect(request.url?.path == "/api/v2/alert-keyword")
            #expect(request.httpMethod == method)
            #expect(try jsonObject(request.httpBody) as? [String: String] == ["keyword": "캐릭터"])
        }

        let targets: [V2AlertKeywordAPI] = [.list, .add(keyword: "캐릭터"), .remove(keyword: "캐릭터")]
        #expect(targets.allSatisfy { $0.resolvedAuthorization == .access })
    }

    @Test("알림 키워드 목록은 APIResponse의 data에서 alertKeyword 배열을 읽는다")
    func alertKeywordListReadsWrappedResponse() async throws {
        let context = Context(response: (200, #"{"success":true,"code":0,"message":"요청 성공!","data":[{"alertKeyword":"캐릭터"},{"alertKeyword":"전시"}]}"#))

        #expect(try await context.repository.getAlertKeywordList().map(\.keyword) == ["캐릭터", "전시"])
    }

    @Test("알림 키워드 등록·삭제는 빈 본문을 성공으로 처리한다")
    func alertKeywordAddAndRemoveAcceptEmptyBody() async throws {
        let context = Context(response: (200, ""))

        try await context.repository.addAlertKeyword(alertKeyword: "캐릭터")
        try await context.repository.removeAlertKeyword(alertKeyword: "캐릭터")
    }

    @Test("이미 있는 키워드 등록(409 4004)은 alreadyExists로, 서버 오류는 failed로 바꾼다")
    func alertKeywordAddMapsErrors() async throws {
        await #expect(throws: AlertKeywordError.alreadyExists) {
            try await Context(response: (409, error(4004))).repository.addAlertKeyword(alertKeyword: "캐릭터")
        }
        await #expect(throws: AlertKeywordError.failed) {
            try await Context(response: (500, error(6000))).repository.addAlertKeyword(alertKeyword: "캐릭터")
        }
        await #expect(throws: AlertKeywordError.failed) {
            _ = try await Context(response: (500, error(6000))).repository.getAlertKeywordList()
        }
    }

    @Test("서버에 없는 키워드 삭제(404 4003)는 지운 것으로 보고, 서버 오류는 failed로 바꾼다")
    func alertKeywordRemoveTreatsMissingAsRemoved() async throws {
        try await Context(response: (404, error(4003))).repository.removeAlertKeyword(alertKeyword: "캐릭터")

        await #expect(throws: AlertKeywordError.failed) {
            try await Context(response: (500, error(6000))).repository.removeAlertKeyword(alertKeyword: "캐릭터")
        }
    }

    @Test("알림 키워드 요청에서 다시 로그인해야 하는 실패는 그대로 던진다")
    func alertKeywordLoginRequiredIsRethrown() async throws {
        await #expect(throws: AuthSessionError.loginRequired) {
            _ = try await Context(response: (401, error(5006))).repository.getAlertKeywordList()
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

/// 로그인한 상태의 토큰 저장소와 인증 plugin, 정해 둔 응답 하나를 돌려주는 Repository
private struct Context {
    static let tokens = AuthTokens(accessToken: "access", refreshToken: "refresh")

    let storage: AuthTokenStorage
    let repository: UserRepositoryImpl

    init(response: (Int, String)) {
        let storage = AuthTokenStorage(store: InMemoryStore())
        try? storage.saveTokens(Self.tokens)
        let authentication = AuthenticationPlugin(
            storage: storage,
            refresher: AccessTokenRefresher(storage: storage) { _ in
                throw NetworkError.invalidStatusCode(401, message: error(5007))
            }
        )
        let networkProvider = NetworkProvider(
            stubClosure: MoyaProvider.immediatelyStub,
            authentication: authentication
        )

        func makeProvider<T: TargetType>() -> MoyaProvider<T> {
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

        self.storage = storage
        self.repository = UserRepositoryImpl(
            makeV2Provider: { makeProvider() },
            makeV2AlertKeywordProvider: { makeProvider() }
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
