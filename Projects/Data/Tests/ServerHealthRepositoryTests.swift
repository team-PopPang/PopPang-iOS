import Domain
import Foundation
import Testing
@testable import Data

/// 가짜 응답의 정적 상태를 공유하므로 테스트를 순서대로 실행한다.
@Suite(.serialized)
struct ServerHealthRepositoryTests {
    @Test("200과 isHealthy true를 받으면 정상으로 판정한다")
    func healthyWhenOKAndHealthy() async {
        let repository = makeRepository(stub: .response(statusCode: 200, body: #"{"isHealthy":true}"#))

        #expect(await repository.checkHealth() == .healthy)
    }

    @Test("200이어도 isHealthy가 false면 서버 이상으로 판정한다")
    func unhealthyWhenOKButNotHealthy() async {
        let repository = makeRepository(stub: .response(statusCode: 200, body: #"{"isHealthy":false}"#))

        #expect(await repository.checkHealth() == .unhealthy)
    }

    @Test(
        "200이어도 본문이 예상 형식과 다르면 서버 이상으로 판정한다",
        arguments: ["OK", #"{"status":"UP"}"#, ""]
    )
    func unhealthyWhenBodyIsUnexpected(body: String) async {
        let repository = makeRepository(stub: .response(statusCode: 200, body: body))

        #expect(await repository.checkHealth() == .unhealthy)
    }

    @Test(
        "200이 아닌 응답은 본문과 관계없이 서버 이상으로 판정한다",
        arguments: [
            (500, #"{"success":false,"code":6000,"message":"서버 에러가 발생했습니다.","data":null}"#),
            (503, ""),
            (204, #"{"isHealthy":true}"#),
        ]
    )
    func unhealthyWhenStatusIsNotOK(statusCode: Int, body: String) async {
        let repository = makeRepository(stub: .response(statusCode: statusCode, body: body))

        #expect(await repository.checkHealth() == .unhealthy)
    }

    @Test(
        "타임아웃과 서버 연결 실패는 서버 이상으로 판정한다",
        arguments: [URLError.Code.timedOut, .cannotConnectToHost, .cannotFindHost, .networkConnectionLost]
    )
    func unhealthyWhenServerIsUnreachable(code: URLError.Code) async {
        let repository = makeRepository(stub: .failure(code))

        #expect(await repository.checkHealth() == .unhealthy)
    }

    @Test(
        "기기 인터넷 연결이 없으면 오프라인으로 판정한다",
        arguments: [URLError.Code.notConnectedToInternet, .dataNotAllowed, .internationalRoamingOff]
    )
    func offlineWhenDeviceHasNoConnection(code: URLError.Code) async {
        let repository = makeRepository(stub: .failure(code))

        #expect(await repository.checkHealth() == .offline)
    }

    @Test("헬스 체크는 GET /api/v1/health를 5초 제한으로 요청한다")
    func requestsHealthEndpointWithTimeout() async throws {
        let repository = makeRepository(stub: .response(statusCode: 200, body: #"{"isHealthy":true}"#))

        _ = await repository.checkHealth()

        let request = try #require(ServerHealthStubURLProtocol.lastRequest)
        #expect(request.httpMethod == "GET")
        #expect(request.url?.absoluteString == "https://poppang.co.kr/api/v1/health")
        #expect(request.timeoutInterval == 5)
    }

    @Test("헬스 체크 세션은 요청 전체 시간을 5초로 제한하고 캐시를 쓰지 않는다")
    func sessionLimitsTotalTimeAndSkipsCache() {
        let configuration = ServerHealthRepositoryImpl.makeSession().configuration

        #expect(configuration.timeoutIntervalForRequest == 5)
        #expect(configuration.timeoutIntervalForResource == 5)
        #expect(configuration.requestCachePolicy == .reloadIgnoringLocalCacheData)
        #expect(configuration.waitsForConnectivity == false)
    }

    @Test("Usecase는 Repository의 판정 결과를 그대로 돌려준다")
    func usecaseReturnsRepositoryResult() async {
        let repository = makeRepository(stub: .failure(.notConnectedToInternet))
        let usecase: ServerHealthUsecaseProtocol = ServerHealthUsecaseImpl(serverHealthRepository: repository)

        #expect(await usecase.checkHealth() == .offline)
    }
}

private extension ServerHealthRepositoryTests {
    func makeRepository(stub: ServerHealthStubURLProtocol.Stub) -> ServerHealthRepositoryImpl {
        ServerHealthStubURLProtocol.stub = stub
        ServerHealthStubURLProtocol.lastRequest = nil

        let configuration = ServerHealthRepositoryImpl.makeSession().configuration
        configuration.protocolClasses = [ServerHealthStubURLProtocol.self]
        return ServerHealthRepositoryImpl(session: URLSession(configuration: configuration))
    }
}

/// 실제 네트워크 대신 정해 둔 응답이나 오류를 돌려준다.
private final class ServerHealthStubURLProtocol: URLProtocol {
    enum Stub {
        case response(statusCode: Int, body: String)
        case failure(URLError.Code)
    }

    static var stub: Stub = .failure(.unknown)
    static var lastRequest: URLRequest?

    override class func canInit(with request: URLRequest) -> Bool {
        true
    }

    override class func canonicalRequest(for request: URLRequest) -> URLRequest {
        request
    }

    override func startLoading() {
        Self.lastRequest = request

        switch Self.stub {
        case let .response(statusCode, body):
            guard let url = request.url,
                  let response = HTTPURLResponse(
                      url: url,
                      statusCode: statusCode,
                      httpVersion: "HTTP/1.1",
                      headerFields: ["Content-Type": "application/json"]
                  )
            else {
                client?.urlProtocol(self, didFailWithError: URLError(.badURL))
                return
            }

            client?.urlProtocol(self, didReceive: response, cacheStoragePolicy: .notAllowed)
            client?.urlProtocol(self, didLoad: Data(body.utf8))
            client?.urlProtocolDidFinishLoading(self)

        case .failure(let code):
            client?.urlProtocol(self, didFailWithError: URLError(code))
        }
    }

    override func stopLoading() {}
}
