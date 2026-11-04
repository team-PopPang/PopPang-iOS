import Core
import Domain
import Foundation
import Moya
import Testing
@testable import Data

struct AdminRepositoryTests {
    @Test("S02 팝업 비활성화는 V2 경로에 PATCH로 query 없이 보내고 Access Token을 쓴다")
    func s02DeactivateRequestMatchesV2Contract() throws {
        let request = try MoyaProvider<V2AdminAPI>.defaultEndpointMapping(for: .deactivatePopup(popupUuid: "popup-1")).urlRequest()

        #expect(request.url?.path == "/api/v2/admin/popup/popup-1/deactivate")
        #expect(request.url?.query == nil)
        #expect(request.httpMethod == "PATCH")
        #expect(request.httpBody == nil)
        #expect(V2AdminAPI.deactivatePopup(popupUuid: "popup-1").resolvedAuthorization == .access)
    }

    @Test("S02 팝업 비활성화가 성공하면 Access Token을 담아 한 번 보낸다")
    func s02DeactivateSendsAccessToken() async throws {
        let context = AdminRepositoryContext(response: (200, ""))

        try await context.repository.deactivatePopup(popupUuid: "popup-1")

        #expect(context.recorder.authorizationHeaders == ["Bearer access"])
        #expect(context.recorder.httpMethods == ["PATCH"])
    }

    @Test("S02 팝업 비활성화가 서버 오류나 권한 없음으로 실패하면 PopupError로 바꾼다", arguments: [
        (403, #"{"success":false,"code":5005,"message":"error","data":null}"#),
        (500, #"{"success":false,"code":9999,"message":"error","data":null}"#),
    ])
    func s02DeactivateMapsFailureToPopupError(response: (Int, String)) async {
        let context = AdminRepositoryContext(response: response)

        await #expect(throws: PopupError.failed) {
            try await context.repository.deactivatePopup(popupUuid: "popup-1")
        }
    }

    @Test("S02 다시 로그인해야 하는 실패는 바꾸지 않고 그대로 던진다")
    func s02DeactivatePassesLoginRequiredThrough() async {
        let context = AdminRepositoryContext(response: (401, #"{"success":false,"code":5001,"message":"error","data":null}"#))

        await #expect(throws: AuthSessionError.loginRequired) {
            try await context.repository.deactivatePopup(popupUuid: "popup-1")
        }
    }
}

/// 관리자 Repository에 가짜 응답과 Access Token을 넣는다. 팝업 Repository 테스트 도구를 함께 쓴다.
struct AdminRepositoryContext {
    let recorder: RequestRecorder
    let repository: AdminRepositoryImpl

    init(response: (Int, String)) {
        let storage = AuthTokenStorage(store: PopupTestStore())
        try? storage.saveTokens(AuthTokens(accessToken: "access", refreshToken: "refresh"))
        let authentication = AuthenticationPlugin(
            storage: storage,
            refresher: AccessTokenRefresher(storage: storage) { _ in
                throw NetworkError.invalidStatusCode(401, message: #"{"success":false,"code":5007,"message":"error","data":null}"#)
            }
        )
        let networkProvider = NetworkProvider(stubClosure: MoyaProvider.immediatelyStub, authentication: authentication)
        let recorder = RequestRecorder()

        self.recorder = recorder
        self.repository = AdminRepositoryImpl(makeV2Provider: {
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
        })
    }
}
