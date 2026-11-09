import Core
import Domain
import Foundation
import Moya
import Testing
@testable import Data

struct AlertRepositoryTests {
    @Test("알림함 목록·삭제는 V2 경로에 사용자 UUID 없이 Access Token으로 보내고, 삭제는 본문에 popupUuid만 담는다")
    func requestsMatchV2Contract() throws {
        let list = try MoyaProvider<V2AlertAPI>.defaultEndpointMapping(for: .popups).urlRequest()
        let remove = try MoyaProvider<V2AlertAPI>.defaultEndpointMapping(for: .remove(popupUuid: "popup-1")).urlRequest()

        #expect(list.url?.path == "/api/v2/user/alert/popups")
        #expect(list.httpMethod == "GET")
        #expect(list.httpBody == nil)
        #expect(remove.url?.path == "/api/v2/user/alert")
        #expect(remove.httpMethod == "DELETE")
        let body = try JSONSerialization.jsonObject(with: try #require(remove.httpBody)) as? [String: String]
        #expect(body == ["popupUuid": "popup-1"])
        for target in [V2AlertAPI.popups, .remove(popupUuid: "popup-1")] {
            #expect(target.resolvedAuthorization == .access)
        }
    }

    @Test("알림함 목록은 APIResponse의 data에서 팝업 배열을 읽고, 읽음 여부(isRead)가 있어도 디코딩한다")
    func listReadsWrappedPopups() async throws {
        let popup = PopupFixture.popup.replacingOccurrences(of: #""recommendList":null}"#, with: #""recommendList":null,"isRead":false}"#)
        let context = PopupRepositoryContext(response: (200, #"{"success":true,"code":0,"message":"요청 성공!","data":[\#(popup)]}"#))

        let popups = try await context.repository.getAlertPopupList()

        #expect(popups.map(\.popupUuid) == ["popup-1"])
        #expect(context.recorder.authorizationHeaders == ["Bearer access"])
    }

    @Test("알림 삭제는 본문 없는 200을 성공으로 처리한다")
    func removeAcceptsEmptyBody() async throws {
        let context = PopupRepositoryContext(response: (200, ""))

        try await context.repository.removeAlertPopup(popupUuid: "popup-1")

        #expect(context.recorder.httpMethods == ["DELETE"])
    }

    @Test("알림 기록 없음(404 4001)·서버 오류는 PopupError로 바꾼다", arguments: [
        (404, #"{"success":false,"code":4001,"message":"해당 팝업에 대한 알림 이력이 존재하지 않습니다.","data":null}"#),
        (500, #"{"success":false,"code":6000,"message":"서버 에러","data":null}"#),
    ])
    func failuresMapToPopupError(response: (Int, String)) async {
        let context = PopupRepositoryContext(response: response)

        await #expect(throws: PopupError.failed) {
            try await context.repository.removeAlertPopup(popupUuid: "popup-1")
        }
        await #expect(throws: PopupError.failed) {
            _ = try await context.repository.getAlertPopupList()
        }
    }

    @Test("다시 로그인해야 하는 실패는 그대로 던진다")
    func loginRequiredPassesThrough() async {
        let context = PopupRepositoryContext(response: (401, #"{"success":false,"code":5001,"message":"error","data":null}"#))

        await #expect(throws: AuthSessionError.loginRequired) {
            _ = try await context.repository.getAlertPopupList()
        }
    }
}
