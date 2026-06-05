import Foundation
import Domain
import Moya
import Testing
@testable import Data

struct DataTests {
    @Test("Data repository 구현체가 Domain repository contract와 usecase 주입 계약을 만족한다")
    func repositoryImplementationsSatisfyDomainContracts() {
        let popupRepository: PopupRepositoryProtocol = PopupRepositoryImpl()
        let userRepository: UserRepositoryProtocol = UserRepositoryImpl()
        let adminRepository: AdminRepositoryProtocol = AdminRepositoryImpl()
        let appleRepository: AppleAuthRepositoryProtocol = AppleAuthRepositoryImpl()
        let googleRepository: GoogleAuthRepositoryProtocol = GoogleAuthRepositoryImpl()
        let kakaoRepository: KakaoAuthRepositoryProtocol = KakaoAuthRepositoryImpl()

        let popupUsecase: PopupUsecaseProtocol = PopupUsecaseImpl(popupRepository: popupRepository)
        let userUsecase: UserUsecaseProtocol = UserUsecaseImpl(userRepository: userRepository)
        let adminUsecase: AdminUsecaseProtocol = AdminUsecaseImpl(adminRepository: adminRepository)
        let appleUsecase: AppleAuthUsecaseProtocol = AppleAuthUsecaseImpl(appleAuthRepository: appleRepository)
        let googleUsecase: GoogleAuthUsecaseProtocol = GoogleAuthUsecaseImpl(googleAuthRepository: googleRepository)
        let kakaoUsecase: KakaoAuthUsecaseProtocol = KakaoAuthUsecaseImpl(kakaoAuthRepository: kakaoRepository)

        #expect(contractTypeName(of: popupUsecase) == "PopupUsecaseImpl")
        #expect(contractTypeName(of: userUsecase) == "UserUsecaseImpl")
        #expect(contractTypeName(of: adminUsecase) == "AdminUsecaseImpl")
        #expect(contractTypeName(of: appleUsecase) == "AppleAuthUsecaseImpl")
        #expect(contractTypeName(of: googleUsecase) == "GoogleAuthUsecaseImpl")
        #expect(contractTypeName(of: kakaoUsecase) == "KakaoAuthUsecaseImpl")
    }

    @Test("팝업 DTO가 V0 필드와 이미지 URL을 도메인 모델로 변환한다")
    func popupDTOMapsLegacyFieldsAndImageURLsToDomainModel() throws {
        let json = """
        {
          "popupUuid": "popup-1",
          "name": "성수 팝업",
          "startDate": "26.05.01",
          "endDate": "26.05.31",
          "openTime": "10:00",
          "closeTime": "20:00",
          "address": "서울 성동구",
          "roadAddress": "서울 성동구 성수이로",
          "region": "서울",
          "latitude": 37.544,
          "longitude": 127.055,
          "instaPostId": "post-1",
          "instaPostUrl": "https://instagram.com/p/post-1",
          "captionSummary": "요약",
          "imageUrlList": ["/image-a.png", "https://cdn.example.com/image-b.png"],
          "mediaType": "video",
          "favoriteCount": 12,
          "viewCount": 34,
          "isFavorited": true,
          "recommendList": ["캐릭터", "라이프스타일"]
        }
        """.data(using: .utf8)!

        let dto = try JSONDecoder().decode(PopupDTO.self, from: json)
        let popup = dto.toEntity()

        #expect(popup.popupUuid == "popup-1")
        #expect(popup.name == "성수 팝업")
        #expect(popup.openTime == "10:00")
        #expect(popup.closeTime == "20:00")
        #expect(popup.region == "서울")
        #expect(popup.latitude == 37.544)
        #expect(popup.longitude == 127.055)
        #expect(popup.instaPostUrl == "https://instagram.com/p/post-1")
        #expect(popup.mediaType == .video)
        #expect(popup.favoriteCount == 12)
        #expect(popup.viewCount == 34)
        #expect(popup.isFavorited)
        #expect(popup.recommendList == ["캐릭터", "라이프스타일"])
        #expect(popup.imageUrlList[0].hasSuffix("/image-a.png"))
        #expect(popup.imageUrlList[1] == "https://cdn.example.com/image-b.png")
        #expect(Calendar.current.component(.year, from: popup.startDate) == 2026)
        #expect(Calendar.current.component(.month, from: popup.startDate) == 5)
        #expect(Calendar.current.component(.day, from: popup.startDate) == 1)
    }

    @Test("팝업 DTO가 인스타 URL 누락과 null을 허용한다")
    func popupDTOAllowsMissingInstagramURL() throws {
        let missingURLJSON = """
        {
          "popupUuid": "popup-1",
          "name": "성수 팝업",
          "startDate": "26.05.01",
          "endDate": "26.05.31",
          "openTime": null,
          "closeTime": null,
          "address": "서울 성동구",
          "roadAddress": "서울 성동구 성수이로",
          "region": "서울",
          "latitude": null,
          "longitude": null,
          "captionSummary": "요약",
          "imageUrlList": [],
          "mediaType": "image",
          "favoriteCount": 0,
          "viewCount": 0,
          "isFavorited": false,
          "recommendList": []
        }
        """.data(using: .utf8)!

        let nullURLJSON = """
        {
          "popupUuid": "popup-2",
          "name": "성수 팝업",
          "startDate": "26.05.01",
          "endDate": "26.05.31",
          "openTime": null,
          "closeTime": null,
          "address": "서울 성동구",
          "roadAddress": "서울 성동구 성수이로",
          "region": "서울",
          "latitude": null,
          "longitude": null,
          "instaPostId": null,
          "instaPostUrl": null,
          "captionSummary": "요약",
          "imageUrlList": [],
          "mediaType": "image",
          "favoriteCount": 0,
          "viewCount": 0,
          "isFavorited": false,
          "recommendList": []
        }
        """.data(using: .utf8)!

        let missingURLPopup = try JSONDecoder().decode(PopupDTO.self, from: missingURLJSON).toEntity()
        let nullURLPopup = try JSONDecoder().decode(PopupDTO.self, from: nullURLJSON).toEntity()

        #expect(missingURLPopup.instaPostId == nil)
        #expect(missingURLPopup.instaPostUrl == nil)
        #expect(nullURLPopup.instaPostId == nil)
        #expect(nullURLPopup.instaPostUrl == nil)
    }

    @Test("단순 DTO들이 V0와 같은 도메인 모델 값으로 변환된다")
    func simpleDTOsMapToDomainModelsLikeV0() {
        let keyword = KeywordDTO(keyword: "팝업스토어").toModel()
        let recommend = RecommendListDTO(id: 7, recommendName: "캐릭터").toModel()
        let region = RegionListDTO(region: "서울", districtList: ["성동구", "마포구"]).toEntity()
        let user = UserDTO(
            userUuid: "user-1",
            uid: "oauth-1",
            provider: "KAKAO",
            email: "index@example.com",
            nickname: "팝팡",
            role: "USER",
            isAlerted: true,
            fcmToken: "fcm-token",
            alertKeywordList: ["성수"],
            recommendList: [7]
        ).toModel()

        #expect(keyword.keyword == "팝업스토어")
        #expect(recommend.id == 7)
        #expect(recommend.recommendName == "캐릭터")
        #expect(region.region == "서울")
        #expect(region.districtList == ["성동구", "마포구"])
        #expect(user.userUuid == "user-1")
        #expect(user.uid == "oauth-1")
        #expect(user.provider == "KAKAO")
        #expect(user.email == "index@example.com")
        #expect(user.nickname == "팝팡")
        #expect(user.isAlerted)
        #expect(user.fcmToken == "fcm-token")
        #expect(user.alertKeywordList == ["성수"])
        #expect(user.recommendList == [7])
    }

    @Test("팝업 제보 요청 엔티티가 서버 DTO 날짜 형식으로 변환된다")
    func popupSubmissionCreateRequestMapsToServerDTO() throws {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "ko_KR")
        formatter.dateFormat = "yyyy-MM-dd"

        let request = PopupSubmissionCreateRequest(
            name: "성수 팝업",
            startDate: try #require(formatter.date(from: "2026-06-03")),
            endDate: try #require(formatter.date(from: "2026-06-10")),
            address: "서울 성동구 성수이로 00",
            description: "브랜드 팝업 제보",
            submitterUserUuid: "user-1"
        )

        let dto = request.toDTO()

        #expect(dto.name == "성수 팝업")
        #expect(dto.startDate == "2026-06-03")
        #expect(dto.endDate == "2026-06-10")
        #expect(dto.address == "서울 성동구 성수이로 00")
        #expect(dto.description == "브랜드 팝업 제보")
        #expect(dto.submitterUserUuid == "user-1")

        let dtoObject = try JSONSerialization.jsonObject(with: JSONEncoder().encode(dto)) as? [String: Any]
        #expect(dtoObject?["submitterUserUuid"] as? String == "user-1")
        #expect(dtoObject?["submitterUserId"] == nil)
    }

    @Test("팝업 제보 상태 엔티티가 서버 DTO로 변환된다")
    func popupSubmissionStatusMapsToServerDTO() throws {
        let dto = PopupSubmissionStatus.approved.toDTO()
        let dtoObject = try JSONSerialization.jsonObject(with: JSONEncoder().encode(dto)) as? [String: Any]

        #expect(dto.popupSubmissionStatus == "APPROVED")
        #expect(dtoObject?["popupSubmissionStatus"] as? String == "APPROVED")
    }

    @Test("팝업 제보 목록 DTO가 서버 응답을 도메인 모델로 변환한다")
    func popupSubmissionDTOMapsToDomainModel() throws {
        let json = """
        {
          "id": 7,
          "name": "성수 팝업",
          "startDate": "2026-06-03",
          "endDate": "2026-06-10",
          "address": "서울 성동구 성수이로 00",
          "description": "브랜드 팝업 제보",
          "status": "PENDING",
          "createdAt": "2026-06-05T10:20:30.000Z"
        }
        """.data(using: .utf8)!

        let submission = try JSONDecoder().decode(PopupSubmissionDTO.self, from: json).toEntity()

        #expect(submission.id == 7)
        #expect(submission.name == "성수 팝업")
        #expect(submission.startDate == "2026-06-03")
        #expect(submission.endDate == "2026-06-10")
        #expect(submission.address == "서울 성동구 성수이로 00")
        #expect(submission.description == "브랜드 팝업 제보")
        #expect(submission.status == .pending)
        #expect(submission.createdAt == "2026-06-05T10:20:30.000Z")
    }

    @Test("API 경로가 현재 명세와 일치한다")
    func apiPathsMatchEndpointDefinitions() {
        #expect(AdminAPI.getPopupSubmissionList.path == "/admin/popup-submissions")
        #expect(AdminAPI.createPopupSubmission(requestDTO: .fixture).path == "/admin/popup-submissions")
        #expect(AdminAPI.deactivatePopupByUser(userUuid: "user-1", popupUuid: "popup-1").path == "/admin/user/user-1/popup/popup-1/deactivate")
        #expect(AdminAPI.deactivatePopup(popupUuid: "popup-1").path == "/admin/popup/popup-1/deactivate")
        #expect(AdminAPI.updatePopupSubmissionStatus(
            submissionId: 7,
            requestDTO: PopupSubmissionStatus.approved.toDTO()
        ).path == "/admin/popup-submissions/7/status")

        #expect(AppleAuthAPI.login(authCode: "auth").path == "/auth/apple/mobile/login")
        #expect(AppleAuthAPI.signup(userDto: UserDTO.adminUser).path == "/auth/apple/signup")
        #expect(GoogleAuthAPI.login(idToken: "id-token").path == "/auth/google/mobile/login")
        #expect(GoogleAuthAPI.signup(userDTO: UserDTO.adminUser).path == "/auth/google/signup")
        #expect(KakaoAuthAPI.login(accessToken: "token").path == "/auth/kakao/mobile/login")
        #expect(KakaoAuthAPI.signup(userDTO: UserDTO.adminUser).path == "/auth/kakao/signup")

        #expect(PopupAPI.getPopupList.path == "/popup")
        #expect(PopupAPI.getUpcomingPopupList.path == "/popup/upcoming")
        #expect(PopupAPI.getInProgressPopupList.path == "/popup/inProgress")
        #expect(PopupAPI.searchPopupList(searchText: "성수").path == "/popup/search")
        #expect(PopupAPI.increaseViewCount(popupUuid: "popup-1").path == "/popup/popup-1/view")
        #expect(PopupAPI.getRandomPopupList.path == "/popup/random")
        #expect(PopupAPI.getPersonalPopupList(userUuid: "user-1").path == "/users/user-1/popups")
        #expect(PopupAPI.getPersonalUseerRecommendPopupList(userUuid: "user-1").path == "/users/user-1/popups/recommend")
        #expect(PopupAPI.getPersonalUpcomingPopupList(userUuid: "user-1").path == "/users/user-1/popups/upcoming")
        #expect(PopupAPI.getPersonalFilteredPopupList(userUuid: "user-1", region: "서울", district: "성동구", homeSortStandard: "NEWEST").path == "/users/user-1/popups/filtered/home")
        #expect(PopupAPI.getPersonalSearchPopupList(userUuid: "user-1", searchText: "성수").path == "/users/user-1/popups/search")
        #expect(PopupAPI.getPersonalMapFilteredPopupList(userUuid: "user-1", region: "서울", district: "성동구", latitude: nil, longitude: nil, mapSortStandard: "DISTANCE").path == "/users/user-1/popups/filtered/map")
        #expect(PopupAPI.getPersonalRelatedPopupList(userUuid: "user-1", popupUuid: "popup-1").path == "/users/user-1/popups/popup-1/related")
        #expect(PopupAPI.getPersonalRandomPopupList(userUuid: "user-1").path == "/users/user-1/popups/random")
        #expect(PopupAPI.getAlertPopupList(userUuid: "user-1").path == "/users/user-1/alert/popups")
        #expect(PopupAPI.removeAlertPopup(userUuid: "user-1", popupUuid: "popup-1").path == "/users/user-1/alert")
        #expect(PopupAPI.addFavorite(userUuid: "user-1", popupUuid: "popup-1").path == "/favorite")
        #expect(PopupAPI.removeFavorite(userUuid: "user-1", popupUuid: "popup-1").path == "/favorite")
        #expect(PopupAPI.getFavoriteList(userUuid: "user-1").path == "/favorite/popup/user-1")
        #expect(PopupAPI.getRegionList.path == "/popup/regions/districts")
        #expect(PopupAPI.getPopularRecommendList.path == "recommend/featured")
        #expect(PopupAPI.getPopularRecommendPopupList(userUuid: "user-1", recommendId: 7).path == "/users/user-1/popups/recommendations/7")

        #expect(UserAPI.checkNickname(nickname: "팝팡").path == "/user/nickname/duplicated")
        #expect(UserAPI.updateNickname(userUuid: "user-1", newNickname: "새팝팡").path == "/user/user-1")
        #expect(UserAPI.autoLogin(userUuid: "user-1").path == "/auth/autoLogin")
        #expect(UserAPI.getRecommendList.path == "/recommend")
        #expect(UserAPI.hardDeleteUser(userUuid: "user-1").path == "/user/user-1/hard-delete")
        #expect(UserAPI.getAlertKeywordList(userUuid: "user-1").path == "/alert-keyword")
        #expect(UserAPI.addAlertKeyword(userUuid: "user-1", newAlertKeyword: "성수").path == "/alert-keyword")
        #expect(UserAPI.removeAlertKeyword(userUuid: "user-1", deleteAlertKeyword: "성수").path == "/alert-keyword")
        #expect(UserAPI.alertStatus(userUuid: "user-1", isAlerted: true).path == "/user/user-1/alert-status")
        #expect(UserAPI.checkFcmToken(userUuid: "user-1", fcmToken: "fcm").path == "/user/user-1/fcm-token/duplicate-check")
        #expect(UserAPI.updateFcmToken(userUuid: "user-1", newFcmToken: "fcm").path == "/user/user-1/fcm-token/update")
    }

    @Test("API 메서드가 현재 명세와 일치한다")
    func apiMethodsMatchEndpointDefinitions() {
        #expect(AdminAPI.getPopupSubmissionList.method == .get)
        #expect(AdminAPI.createPopupSubmission(requestDTO: .fixture).method == .post)
        #expect(AdminAPI.deactivatePopupByUser(userUuid: "user-1", popupUuid: "popup-1").method == .patch)
        #expect(AdminAPI.deactivatePopup(popupUuid: "popup-1").method == .patch)
        #expect(AdminAPI.updatePopupSubmissionStatus(
            submissionId: 7,
            requestDTO: PopupSubmissionStatus.approved.toDTO()
        ).method == .patch)

        #expect(AppleAuthAPI.login(authCode: "auth").method == .post)
        #expect(AppleAuthAPI.loginWithEmail(authCode: "auth", email: "index@example.com").method == .post)
        #expect(AppleAuthAPI.signup(userDto: UserDTO.adminUser).method == .post)
        #expect(GoogleAuthAPI.login(idToken: "id-token").method == .post)
        #expect(GoogleAuthAPI.signup(userDTO: UserDTO.adminUser).method == .post)
        #expect(KakaoAuthAPI.login(accessToken: "token").method == .post)
        #expect(KakaoAuthAPI.signup(userDTO: UserDTO.adminUser).method == .post)

        #expect(PopupAPI.getPopupList.method == .get)
        #expect(PopupAPI.getUpcomingPopupList.method == .get)
        #expect(PopupAPI.getInProgressPopupList.method == .get)
        #expect(PopupAPI.searchPopupList(searchText: "성수").method == .get)
        #expect(PopupAPI.increaseViewCount(popupUuid: "popup-1").method == .post)
        #expect(PopupAPI.getRandomPopupList.method == .get)
        #expect(PopupAPI.getPersonalPopupList(userUuid: "user-1").method == .get)
        #expect(PopupAPI.getPersonalUseerRecommendPopupList(userUuid: "user-1").method == .get)
        #expect(PopupAPI.getPersonalUpcomingPopupList(userUuid: "user-1").method == .get)
        #expect(PopupAPI.getPersonalFilteredPopupList(userUuid: "user-1", region: "서울", district: "성동구", homeSortStandard: "NEWEST").method == .get)
        #expect(PopupAPI.getPersonalSearchPopupList(userUuid: "user-1", searchText: "성수").method == .get)
        #expect(PopupAPI.getPersonalMapFilteredPopupList(userUuid: "user-1", region: "서울", district: "성동구", latitude: 37.5, longitude: 127.0, mapSortStandard: "DISTANCE").method == .get)
        #expect(PopupAPI.getPersonalRelatedPopupList(userUuid: "user-1", popupUuid: "popup-1").method == .get)
        #expect(PopupAPI.getPersonalRandomPopupList(userUuid: "user-1").method == .get)
        #expect(PopupAPI.getAlertPopupList(userUuid: "user-1").method == .get)
        #expect(PopupAPI.removeAlertPopup(userUuid: "user-1", popupUuid: "popup-1").method == .delete)
        #expect(PopupAPI.addFavorite(userUuid: "user-1", popupUuid: "popup-1").method == .post)
        #expect(PopupAPI.removeFavorite(userUuid: "user-1", popupUuid: "popup-1").method == .delete)
        #expect(PopupAPI.getFavoriteList(userUuid: "user-1").method == .get)
        #expect(PopupAPI.getRegionList.method == .get)
        #expect(PopupAPI.getPopularRecommendList.method == .get)
        #expect(PopupAPI.getPopularRecommendPopupList(userUuid: "user-1", recommendId: 7).method == .get)

        #expect(UserAPI.checkNickname(nickname: "팝팡").method == .get)
        #expect(UserAPI.updateNickname(userUuid: "user-1", newNickname: "새팝팡").method == .patch)
        #expect(UserAPI.autoLogin(userUuid: "user-1").method == .post)
        #expect(UserAPI.getRecommendList.method == .get)
        #expect(UserAPI.hardDeleteUser(userUuid: "user-1").method == .delete)
        #expect(UserAPI.getAlertKeywordList(userUuid: "user-1").method == .get)
        #expect(UserAPI.addAlertKeyword(userUuid: "user-1", newAlertKeyword: "성수").method == .post)
        #expect(UserAPI.removeAlertKeyword(userUuid: "user-1", deleteAlertKeyword: "성수").method == .delete)
        #expect(UserAPI.alertStatus(userUuid: "user-1", isAlerted: true).method == .patch)
        #expect(UserAPI.checkFcmToken(userUuid: "user-1", fcmToken: "fcm").method == .get)
        #expect(UserAPI.updateFcmToken(userUuid: "user-1", newFcmToken: "fcm").method == .put)
    }

    @Test("API 요청 파라미터가 현재 명세와 일치한다")
    func apiRequestParametersMatchEndpointDefinitions() {
        #expect(stringParameter(PopupAPI.searchPopupList(searchText: "성수").task, key: "q") == "성수")
        #expect(stringParameter(PopupAPI.getPersonalPopupList(userUuid: "user-1").task, key: "userUuid") == "user-1")
        #expect(stringParameter(PopupAPI.getPersonalFilteredPopupList(userUuid: "user-1", region: "서울", district: "성동구", homeSortStandard: "NEWEST").task, key: "region") == "서울")
        #expect(stringParameter(PopupAPI.getPersonalFilteredPopupList(userUuid: "user-1", region: "서울", district: "성동구", homeSortStandard: "NEWEST").task, key: "district") == "성동구")
        #expect(stringParameter(PopupAPI.getPersonalFilteredPopupList(userUuid: "user-1", region: "서울", district: "성동구", homeSortStandard: "NEWEST").task, key: "homeSortStandard") == "NEWEST")

        let mapTask = PopupAPI.getPersonalMapFilteredPopupList(
            userUuid: "user-1",
            region: "서울",
            district: "성동구",
            latitude: 37.5,
            longitude: 127.0,
            mapSortStandard: "DISTANCE"
        ).task
        #expect(stringParameter(mapTask, key: "region") == "서울")
        #expect(stringParameter(mapTask, key: "district") == "성동구")
        #expect(doubleParameter(mapTask, key: "latitude") == 37.5)
        #expect(doubleParameter(mapTask, key: "longitude") == 127.0)
        #expect(stringParameter(mapTask, key: "mapSortStandard") == "DISTANCE")

        #expect(stringParameter(PopupAPI.removeAlertPopup(userUuid: "user-1", popupUuid: "popup-1").task, key: "popupUuid") == "popup-1")
        #expect(stringParameter(PopupAPI.addFavorite(userUuid: "user-1", popupUuid: "popup-1").task, key: "userUuid") == "user-1")
        #expect(stringParameter(PopupAPI.addFavorite(userUuid: "user-1", popupUuid: "popup-1").task, key: "popupUuid") == "popup-1")

        #expect(stringParameter(UserAPI.checkNickname(nickname: "팝팡").task, key: "nickname") == "팝팡")
        #expect(stringParameter(UserAPI.updateNickname(userUuid: "user-1", newNickname: "새팝팡").task, key: "nickname") == "새팝팡")
        #expect(stringParameter(UserAPI.getAlertKeywordList(userUuid: "user-1").task, key: "userUuid") == "user-1")
        #expect(stringParameter(UserAPI.addAlertKeyword(userUuid: "user-1", newAlertKeyword: "성수").task, key: "newAlertKeyword") == "성수")
        #expect(stringParameter(UserAPI.removeAlertKeyword(userUuid: "user-1", deleteAlertKeyword: "성수").task, key: "deleteAlertKeyword") == "성수")
        #expect(boolParameter(UserAPI.alertStatus(userUuid: "user-1", isAlerted: true).task, key: "isAlerted") == true)
        #expect(stringParameter(UserAPI.checkFcmToken(userUuid: "user-1", fcmToken: "fcm").task, key: "fcmToken") == "fcm")
        #expect(stringParameter(UserAPI.updateFcmToken(userUuid: "user-1", newFcmToken: "fcm").task, key: "fcmToken") == "fcm")
    }

    private func stringParameter(_ task: Moya.Task, key: String) -> String? {
        parameter(task, key: key) as? String
    }

    private func doubleParameter(_ task: Moya.Task, key: String) -> Double? {
        parameter(task, key: key) as? Double
    }

    private func boolParameter(_ task: Moya.Task, key: String) -> Bool? {
        parameter(task, key: key) as? Bool
    }

    private func parameter(_ task: Moya.Task, key: String) -> Any? {
        guard case let .requestParameters(parameters, _) = task else {
            return nil
        }
        return parameters[key]
    }

    private func contractTypeName(of value: Any) -> String {
        String(describing: type(of: value))
    }
}

private extension PopupSubmissionCreateRequestDTO {
    static let fixture = PopupSubmissionCreateRequestDTO(
        name: "성수 팝업",
        startDate: "2026-06-03",
        endDate: "2026-06-10",
        address: "서울 성동구 성수이로 00",
        description: "브랜드 팝업 제보",
        submitterUserUuid: "user-1"
    )
}
