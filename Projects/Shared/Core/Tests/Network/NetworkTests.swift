import Foundation
import Moya
import Testing
@testable import Core

struct NetworkTests {
    @Test("BaseAPI가 기본 API URL과 JSON 헤더를 사용한다")
    func baseAPIUsesDefaultBaseURLAndHeaders() {
        let target = TestAPI.sample

        #expect(target.baseURL == NetworkConfig.apiBaseURL)
        #expect(NetworkConfig.imageBaseURL.absoluteString == "https://poppang.co.kr")
        #expect(target.headers?["Content-Type"] == "application/json")
        #expect(target.headers?["accept"] == "application/json")
    }

    @Test("API 버전을 정하지 않은 target은 V1 URL을 쓰고, V2 URL은 버전 경로만 다르다")
    func baseURLDependsOnAPIVersion() {
        #expect(TestAPI.sample.apiVersion == .v1)
        #expect(TestAPI.sample.baseURL.absoluteString == "https://poppang.co.kr/api/v1")
        #expect(NetworkConfig.apiURLString == "https://poppang.co.kr/api/v1")
        #expect(NetworkConfig.apiBaseURL(for: .v2).absoluteString == "https://poppang.co.kr/api/v2")
    }

    @Test("인증 종류를 정하지 않은 target은 헤더를 보내지 않는다")
    func defaultAuthorizationIsNone() {
        #expect(TestAPI.sample.authorization == .none)
        #expect(TestAPI.sample.resolvedAuthorization == .none)
    }

    @Test(
        "실패 본문이 ErrorResponse 형식이면 서버 에러 코드를 읽는다",
        arguments: [
            (401, #"{"success":false,"code":5002,"message":"만료","data":null}"#, 5002 as Int?),
            (500, #"{"success":false,"code":6000,"message":"서버 에러","data":null}"#, 6000),
            (502, "<html>Bad Gateway</html>", nil),
            (503, "", nil),
        ]
    )
    func readsServerErrorCode(statusCode: Int, body: String, expectedCode: Int?) {
        let error = NetworkError.invalidStatusCode(statusCode, message: body)

        #expect(error.statusCode == statusCode)
        #expect(error.serverErrorCode == expectedCode)
        #expect(error.isExpiredToken == (statusCode == 401 && expectedCode == 5002))
    }

    @Test("비동기 요청이 스텁 응답을 디코딩한다")
    func asyncRequestDecodesStubbedResponse() async throws {
        let provider = NetworkProvider(
            stubClosure: MoyaProvider.immediatelyStub,
            trackInflights: false
        ).makeProvider() as MoyaProvider<TestAPI>

        let response: TestResponse = try await provider.asyncRequest(.sample, decodeTo: TestResponse.self)

        #expect(response.message == "ok")
    }

    @Test("APIResponse로 감싼 응답에서 data만 디코딩한다")
    func asyncRequestDecodesWrappedData() async throws {
        let provider = NetworkProvider(
            stubClosure: MoyaProvider.immediatelyStub
        ).makeProvider() as MoyaProvider<TestAPI>

        let response = try await provider.asyncRequest(.wrapped, decodeDataTo: TestResponse.self)

        #expect(response.message == "ok")
    }

    @Test("비동기 요청이 실패 상태 코드에서 네트워크 에러를 던진다")
    func asyncRequestThrowsNetworkErrorForInvalidStatusCode() async {
        let provider = NetworkProvider(
            stubClosure: MoyaProvider.immediatelyStub
        ).makeProvider(
            endpointClosure: { target in
                let url = target.baseURL.appendingPathComponent(target.path).absoluteString
                return Endpoint(
                    url: url,
                    sampleResponseClosure: {
                        .networkResponse(400, target.sampleData)
                    },
                    method: target.method,
                    task: target.task,
                    httpHeaderFields: target.headers
                )
            }
        ) as MoyaProvider<TestAPI>

        await #expect(throws: NetworkError.invalidStatusCode(400, message: "{\"message\":\"bad request\"}")) {
            _ = try await provider.asyncRequest(.failure)
        }
    }
}

private enum TestAPI: BaseAPI {
    case sample
    case wrapped
    case failure

    var path: String {
        switch self {
        case .sample:
            return "/sample"
        case .wrapped:
            return "/wrapped"
        case .failure:
            return "/failure"
        }
    }

    var method: Moya.Method {
        .get
    }

    var task: Task {
        .requestPlain
    }

    var sampleData: Data {
        switch self {
        case .sample:
            return #"{"message":"ok"}"#.data(using: .utf8) ?? Data()
        case .wrapped:
            return #"{"success":true,"code":0,"message":"요청 성공!","data":{"message":"ok"}}"#.data(using: .utf8) ?? Data()
        case .failure:
            return #"{"message":"bad request"}"#.data(using: .utf8) ?? Data()
        }
    }

    var validationType: ValidationType {
        .none
    }
}

private struct TestResponse: Decodable, Equatable {
    let message: String
}
