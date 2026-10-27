import Core
import Domain
import Foundation
import Moya
import Testing
@testable import Data

struct PopupRepositoryTests {
    @Test("회원 팝업 검색은 V2 경로에 사용자 UUID 없이 검색어를 q로 보내고 Access Token을 쓴다")
    func searchRequestMatchesV2Contract() throws {
        let request = try MoyaProvider<V2PopupAPI>.defaultEndpointMapping(for: .search(q: "성수")).urlRequest()

        #expect(request.url?.path == "/api/v2/user/popups/search")
        #expect(URLComponents(url: try #require(request.url), resolvingAgainstBaseURL: false)?.queryItems == [URLQueryItem(name: "q", value: "성수")])
        #expect(request.httpMethod == "GET")
        #expect(V2PopupAPI.search(q: "성수").resolvedAuthorization == .access)
    }

    @Test("회원 팝업 검색은 감싸지 않은 팝업 배열을 읽고 Access Token을 보낸다")
    func searchReadsPopupArray() async throws {
        let context = Context(response: (200, "[\(Fixture.popup)]"))

        let popups = try await context.repository.getPersonalSearchPopupList(searchText: "성수")

        #expect(popups.map(\.popupUuid) == ["popup-1"])
        #expect(popups.first?.isFavorited == true)
        #expect(context.recorder.authorizationHeaders == ["Bearer access"])
    }

    @Test("명세상 null일 수 있는 도로명 주소·미디어 종류·추천 카테고리가 null이어도 목록을 읽는다")
    func searchReadsNullableFields() async throws {
        let context = Context(response: (200, "[\(Fixture.popup)]"))

        let popup = try #require(try await context.repository.getPersonalSearchPopupList(searchText: "성수").first)

        #expect(popup.roadAddress == "서울 성동구")
        #expect(popup.mediaType == .image)
        #expect(popup.recommendList.isEmpty)
    }

    @Test("검색이 서버 오류로 실패하면 화면이 안내할 PopupError로 바꾼다")
    func searchMapsServerErrorToPopupError() async {
        let context = Context(response: (500, #"{"success":false,"code":6000,"message":"서버 에러","data":null}"#))

        await #expect(throws: PopupError.failed) {
            _ = try await context.repository.getPersonalSearchPopupList(searchText: "성수")
        }
    }

    @Test("다시 로그인해야 하는 실패는 바꾸지 않고 그대로 던진다")
    func searchPassesLoginRequiredThrough() async {
        let context = Context(response: (401, #"{"success":false,"code":5001,"message":"error","data":null}"#))

        await #expect(throws: AuthSessionError.loginRequired) {
            _ = try await context.repository.getPersonalSearchPopupList(searchText: "성수")
        }
    }

    @Test("검색 결과가 없으면 빈 배열을 돌려준다")
    func searchReturnsEmptyArray() async throws {
        let context = Context(response: (200, "[]"))

        #expect(try await context.repository.getPersonalSearchPopupList(searchText: "없는팝업").isEmpty)
    }
}

// MARK: - 테스트 도구

private enum Fixture {
    static let popup = """
    {"popupUuid":"popup-1","name":"성수 팝업","startDate":"26.05.01","endDate":"26.05.31","openTime":"10:00","closeTime":"20:00","address":"서울 성동구","roadAddress":null,"region":"서울","latitude":37.544,"longitude":127.055,"instaPostId":null,"instaPostUrl":null,"captionSummary":"요약","imageUrlList":[],"mediaType":null,"favoriteCount":12,"viewCount":34,"isFavorited":true,"recommendList":null}
    """
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

/// 보낸 요청의 `Authorization` 헤더를 기록한다.
private final class HeaderRecorder: PluginType, @unchecked Sendable {
    private let lock = NSLock()
    private var headers: [String?] = []

    var authorizationHeaders: [String?] {
        lock.withLock { headers }
    }

    func willSend(_ request: RequestType, target: TargetType) {
        lock.withLock { headers.append(request.request?.value(forHTTPHeaderField: "Authorization")) }
    }
}

private struct Context {
    let recorder: HeaderRecorder
    let repository: PopupRepositoryImpl

    init(response: (Int, String)) {
        let storage = AuthTokenStorage(store: InMemoryStore())
        try? storage.saveTokens(AuthTokens(accessToken: "access", refreshToken: "refresh"))
        let authentication = AuthenticationPlugin(
            storage: storage,
            refresher: AccessTokenRefresher(storage: storage) { _ in
                throw NetworkError.invalidStatusCode(401, message: #"{"success":false,"code":5007,"message":"error","data":null}"#)
            }
        )
        let networkProvider = NetworkProvider(stubClosure: MoyaProvider.immediatelyStub, authentication: authentication)
        let recorder = HeaderRecorder()

        self.recorder = recorder
        self.repository = PopupRepositoryImpl(
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
                    },
                    plugins: [recorder]
                )
            }
        )
    }
}
