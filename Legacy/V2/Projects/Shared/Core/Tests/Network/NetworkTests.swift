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

    @Test("비동기 요청이 스텁 응답을 디코딩한다")
    func asyncRequestDecodesStubbedResponse() async throws {
        let provider = NetworkProvider(
            stubClosure: MoyaProvider.immediatelyStub,
            trackInflights: false
        ).makeProvider() as MoyaProvider<TestAPI>

        let response: TestResponse = try await provider.asyncRequest(.sample, decodeTo: TestResponse.self)

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
    case failure

    var path: String {
        switch self {
        case .sample:
            return "/sample"
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
