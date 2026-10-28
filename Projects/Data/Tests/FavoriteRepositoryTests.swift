import Core
import Domain
import Foundation
import Moya
import Testing
@testable import Data

struct FavoriteRepositoryTests {
    @Test("찜 목록·등록·해제는 V2 경로에 사용자 UUID 없이 Access Token으로 보낸다")
    func requestsMatchV2Contract() throws {
        let list = try MoyaProvider<V2FavoriteAPI>.defaultEndpointMapping(for: .list).urlRequest()
        let add = try MoyaProvider<V2FavoriteAPI>.defaultEndpointMapping(for: .add(popupUuid: "popup-1")).urlRequest()
        let remove = try MoyaProvider<V2FavoriteAPI>.defaultEndpointMapping(for: .remove(popupUuid: "popup-1")).urlRequest()

        #expect(list.url?.path == "/api/v2/favorite/popup")
        #expect(list.httpMethod == "GET")
        #expect(list.httpBody == nil)
        #expect(add.url?.path == "/api/v2/favorite")
        #expect(add.httpMethod == "POST")
        #expect(remove.url?.path == "/api/v2/favorite")
        #expect(remove.httpMethod == "DELETE")
        for target in [V2FavoriteAPI.list, .add(popupUuid: "popup-1"), .remove(popupUuid: "popup-1")] {
            #expect(target.resolvedAuthorization == .access)
        }
    }

    @Test("찜 등록·해제는 본문에 popupUuid만 JSON으로 담는다. DELETE도 본문을 보낸다")
    func addAndRemoveSendOnlyPopupUuid() throws {
        for target in [V2FavoriteAPI.add(popupUuid: "popup-1"), .remove(popupUuid: "popup-1")] {
            let request = try MoyaProvider<V2FavoriteAPI>.defaultEndpointMapping(for: target).urlRequest()
            let body = try JSONSerialization.jsonObject(with: try #require(request.httpBody)) as? [String: String]

            #expect(body == ["popupUuid": "popup-1"])
            #expect(request.value(forHTTPHeaderField: "Content-Type") == "application/json")
        }
    }

    @Test("찜 목록은 APIResponse의 data에서 팝업 배열을 읽고 Access Token을 보낸다")
    func listReadsWrappedPopups() async throws {
        let context = PopupRepositoryContext(response: (200, #"{"success":true,"code":0,"message":"요청 성공!","data":[\#(PopupFixture.popup)]}"#))

        let popups = try await context.repository.getFavoriteList()

        #expect(popups.map(\.popupUuid) == ["popup-1"])
        #expect(popups.first?.isFavorited == true)
        #expect(context.recorder.authorizationHeaders == ["Bearer access"])
    }

    @Test("찜한 팝업이 없으면 빈 배열을 돌려준다")
    func listReturnsEmptyArray() async throws {
        let context = PopupRepositoryContext(response: (200, #"{"success":true,"code":0,"message":"요청 성공!","data":[]}"#))

        #expect(try await context.repository.getFavoriteList().isEmpty)
    }

    @Test("찜 등록·해제는 본문 없는 200을 성공으로 처리하고 Access Token을 보낸다")
    func addAndRemoveAcceptEmptyBody() async throws {
        let context = PopupRepositoryContext(response: (200, ""))

        try await context.repository.addFavorite(popupUuid: "popup-1")
        try await context.repository.removeFavorite(popupUuid: "popup-1")

        #expect(context.recorder.sentRequests.map(\.httpMethod) == ["POST", "DELETE"])
        #expect(context.recorder.authorizationHeaders == ["Bearer access", "Bearer access"])
    }

    @Test("이미 찜함(409 4101)·찜 없음(404 4102)·서버 오류는 화면이 안내할 PopupError로 바꾼다", arguments: [
        (409, #"{"success":false,"code":4101,"message":"이미 찜한 팝업입니다.","data":null}"#),
        (404, #"{"success":false,"code":4102,"message":"찜 내역이 없습니다.","data":null}"#),
        (500, #"{"success":false,"code":6000,"message":"서버 에러","data":null}"#),
    ])
    func failuresMapToPopupError(response: (Int, String)) async {
        let context = PopupRepositoryContext(response: response)

        await #expect(throws: PopupError.failed) {
            try await context.repository.addFavorite(popupUuid: "popup-1")
        }
        await #expect(throws: PopupError.failed) {
            try await context.repository.removeFavorite(popupUuid: "popup-1")
        }
        await #expect(throws: PopupError.failed) {
            _ = try await context.repository.getFavoriteList()
        }
    }

    @Test("다시 로그인해야 하는 실패는 바꾸지 않고 그대로 던진다")
    func loginRequiredPassesThrough() async {
        let context = PopupRepositoryContext(response: (401, #"{"success":false,"code":5001,"message":"error","data":null}"#))

        await #expect(throws: AuthSessionError.loginRequired) {
            _ = try await context.repository.getFavoriteList()
        }
        await #expect(throws: AuthSessionError.loginRequired) {
            try await context.repository.removeFavorite(popupUuid: "popup-1")
        }
    }
}
