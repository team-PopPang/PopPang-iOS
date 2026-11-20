import Core
import Domain
import Foundation
import Moya
import Testing
@testable import Data

/// 앱이 호출하는 V2 API가 서버의 모바일 전용 경로(`/api/v2/mobile/...`)만 쓰는지 확인한다.
/// 기준은 서버가 공유한 모바일 API 정리본의 AFTER 40건이다.
/// 관리자 API(`V2AdminAPI`)는 정리본에 없어 서버와 경로를 정하는 중이므로 대상에서 뺀다.
struct MobileAPIRouteTests {
    /// 정리본의 AFTER 40건. 경로 변수 `{popupUuid}`는 아래 요청에서 쓰는 `popup-1`로 바꿔 적는다.
    static let mobileRoutes: Set<String> = [
        // 앱 시작·인증
        "POST /api/v2/mobile/auth/apple/mobile/login",
        "POST /api/v2/mobile/auth/apple/signup",
        "POST /api/v2/mobile/auth/google/mobile/login",
        "POST /api/v2/mobile/auth/google/signup",
        "POST /api/v2/mobile/auth/kakao/mobile/login",
        "POST /api/v2/mobile/auth/kakao/signup",
        "POST /api/v2/mobile/auth/logout",
        "POST /api/v2/mobile/auth/refresh",
        "GET /api/v2/mobile/health",
        // 회원·프로필
        "DELETE /api/v2/mobile/user",
        "GET /api/v2/mobile/user",
        "PATCH /api/v2/mobile/user",
        "DELETE /api/v2/mobile/user/alert",
        "PATCH /api/v2/mobile/user/alert-status",
        "PUT /api/v2/mobile/user/fcm-token",
        "GET /api/v2/mobile/user/nickname/duplicated",
        "GET /api/v2/mobile/user/nickname/recommendation",
        "PATCH /api/v2/mobile/user/signup-os",
        // 팝업·지도·제보
        "POST /api/v2/mobile/popup-submissions",
        "GET /api/v2/mobile/popup/regions/districts",
        "POST /api/v2/mobile/popup/popup-1/view",
        "GET /api/v2/mobile/recommend",
        "GET /api/v2/mobile/recommend/map",
        "GET /api/v2/mobile/user/popups",
        "GET /api/v2/mobile/user/popups/filtered/home",
        "GET /api/v2/mobile/user/popups/filtered/map",
        "GET /api/v2/mobile/user/popups/random",
        "GET /api/v2/mobile/user/popups/search",
        "GET /api/v2/mobile/user/popups/upcoming",
        "GET /api/v2/mobile/user/popups/popup-1",
        "GET /api/v2/mobile/user/popups/popup-1/related",
        // 찜·알림·키워드
        "DELETE /api/v2/mobile/alert-keyword",
        "GET /api/v2/mobile/alert-keyword",
        "POST /api/v2/mobile/alert-keyword",
        "GET /api/v2/mobile/alert-keyword/popular",
        "DELETE /api/v2/mobile/favorite",
        "POST /api/v2/mobile/favorite",
        "GET /api/v2/mobile/favorite/popup",
        "GET /api/v2/mobile/user/alert/popups",
        "PATCH /api/v2/mobile/user/alert/read",
    ]

    @Test("정리본의 AFTER 목록은 40건이다")
    func mobileRouteCount() {
        #expect(Self.mobileRoutes.count == 40)
    }

    @Test("앱이 호출하는 V2 API는 모두 정리본의 AFTER 경로 중 하나다")
    func everyAppRouteIsMobileRoute() throws {
        let popupUuid = "popup-1"
        var routes: [String] = []

        for credential in [
            SocialCredential.kakao(accessToken: "token"),
            .google(idToken: "token"),
            .apple(authCode: "code", rawNonce: "nonce"),
        ] {
            routes.append(try route(AuthAPI.login(credential)))
        }
        let signupRequest = V2SignupRequestDTO(SignupRequest(
            nickname: "팝팡",
            isAlerted: true,
            fcmToken: "fcm",
            alertKeywordList: ["전시"],
            recommendList: [1, 2]
        ))
        for provider in [Provider.kakao, .google, .apple] {
            routes.append(try route(AuthAPI.signup(provider: provider, request: signupRequest)))
        }
        routes += try [
            AuthAPI.signupNicknameDuplicated(nickname: "팝팡"),
            .signupRecommendList,
            .signupNicknameRecommendation,
            .popularAlertKeywords,
            .logout(accessToken: "access"),
            .me,
        ].map(route)
        routes.append(try route(AuthTokenRefreshAPI.refresh(refreshToken: "refresh")))
        routes.append(try route(ServerHealthAPI.getHealth))
        routes.append(try route(MigrationAPI.fillSignupOs(accessToken: "access")))
        routes += try [
            V2UserAPI.checkNickname(nickname: "팝팡"),
            .updateNickname(nickname: "새팝팡"),
            .alertStatus(isAlerted: true),
            .withdraw,
            .updateFcmToken(fcmToken: "device-token"),
        ].map(route)
        routes += try [
            V2PopupAPI.search(q: "성수"),
            .detail(popupUuid: popupUuid),
            .view(popupUuid: popupUuid),
            .related(popupUuid: popupUuid),
            .filteredHome(region: "서울", district: "성동구", homeSortStandard: "NEWEST"),
            .regionList,
            .random,
            .upcoming,
            .filteredMap(region: "서울", district: "전체", latitude: nil, longitude: nil, mapSortStandard: "NEWEST", recommendIds: []),
            .recommendMap,
        ].map(route)
        routes += try [V2FavoriteAPI.list, .add(popupUuid: popupUuid), .remove(popupUuid: popupUuid)].map(route)
        routes += try [V2AlertAPI.popups, .remove(popupUuid: popupUuid)].map(route)
        routes += try [V2AlertKeywordAPI.list, .add(keyword: "캐릭터"), .remove(keyword: "캐릭터")].map(route)

        let unknown = routes.filter { !Self.mobileRoutes.contains($0) }
        #expect(unknown.isEmpty, "정리본에 없는 경로: \(unknown)")
    }

    private func route<Target: TargetType>(_ target: Target) throws -> String {
        let request = try MoyaProvider<Target>.defaultEndpointMapping(for: target).urlRequest()
        let method = try #require(request.httpMethod)
        let path = try #require(request.url?.path)
        return "\(method) \(path)"
    }
}
