import Core
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
        let authRepository: AuthRepositoryProtocol = AuthRepositoryImpl(tokenStorage: AuthTokenStorage())
        let serverHealthRepository: ServerHealthRepositoryProtocol = ServerHealthRepositoryImpl()

        let popupUsecase: PopupUsecaseProtocol = PopupUsecaseImpl(popupRepository: popupRepository)
        let userUsecase: UserUsecaseProtocol = UserUsecaseImpl(userRepository: userRepository)
        let adminUsecase: AdminUsecaseProtocol = AdminUsecaseImpl(adminRepository: adminRepository)
        let authUsecase: AuthUsecaseProtocol = AuthUsecaseImpl(authRepository: authRepository)
        let serverHealthUsecase: ServerHealthUsecaseProtocol = ServerHealthUsecaseImpl(serverHealthRepository: serverHealthRepository)

        #expect(contractTypeName(of: popupUsecase) == "PopupUsecaseImpl")
        #expect(contractTypeName(of: userUsecase) == "UserUsecaseImpl")
        #expect(contractTypeName(of: adminUsecase) == "AdminUsecaseImpl")
        #expect(contractTypeName(of: authUsecase) == "AuthUsecaseImpl")
        #expect(contractTypeName(of: serverHealthUsecase) == "ServerHealthUsecaseImpl")
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
        let user = V2AuthUserDTO(
            userUuid: "user-1",
            provider: "KAKAO",
            email: "index@example.com",
            nickname: "팝팡",
            role: "admin",
            isAlerted: true
        ).toEntity()

        #expect(keyword.keyword == "팝업스토어")
        #expect(recommend.id == 7)
        #expect(recommend.recommendName == "캐릭터")
        #expect(region.region == "서울")
        #expect(region.districtList == ["성동구", "마포구"])
        #expect(user.userUuid == "user-1")
        #expect(user.provider == .kakao)
        #expect(user.email == "index@example.com")
        #expect(user.nickname == "팝팡")
        #expect(user.isAdmin)
        #expect(user.isAlerted)
    }

    @Test("API 경로가 현재 명세와 일치한다")
    func apiPathsMatchEndpointDefinitions() {
        #expect(PopupAPI.getPersonalFilteredPopupList(userUuid: "user-1", region: "서울", district: "성동구", homeSortStandard: "NEWEST").path == "/users/user-1/popups/filtered/home")
        #expect(PopupAPI.getPersonalMapFilteredPopupList(userUuid: "user-1", region: "서울", district: "성동구", latitude: nil, longitude: nil, mapSortStandard: "DISTANCE").path == "/users/user-1/popups/filtered/map")
        #expect(PopupAPI.addFavorite(userUuid: "user-1", popupUuid: "popup-1").path == "/favorite")
        #expect(PopupAPI.removeFavorite(userUuid: "user-1", popupUuid: "popup-1").path == "/favorite")
        #expect(PopupAPI.getPopularRecommendList.path == "recommend/featured")
        #expect(PopupAPI.getPopularRecommendPopupList(userUuid: "user-1", recommendId: 7).path == "/users/user-1/popups/recommendations/7")
    }

    @Test("API 메서드가 현재 명세와 일치한다")
    func apiMethodsMatchEndpointDefinitions() {
        #expect(PopupAPI.getPersonalFilteredPopupList(userUuid: "user-1", region: "서울", district: "성동구", homeSortStandard: "NEWEST").method == .get)
        #expect(PopupAPI.getPersonalMapFilteredPopupList(userUuid: "user-1", region: "서울", district: "성동구", latitude: 37.5, longitude: 127.0, mapSortStandard: "DISTANCE").method == .get)
        #expect(PopupAPI.addFavorite(userUuid: "user-1", popupUuid: "popup-1").method == .post)
        #expect(PopupAPI.removeFavorite(userUuid: "user-1", popupUuid: "popup-1").method == .delete)
        #expect(PopupAPI.getPopularRecommendList.method == .get)
        #expect(PopupAPI.getPopularRecommendPopupList(userUuid: "user-1", recommendId: 7).method == .get)
    }

    @Test("API 요청 파라미터가 현재 명세와 일치한다")
    func apiRequestParametersMatchEndpointDefinitions() {
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

        #expect(stringParameter(PopupAPI.addFavorite(userUuid: "user-1", popupUuid: "popup-1").task, key: "userUuid") == "user-1")
        #expect(stringParameter(PopupAPI.addFavorite(userUuid: "user-1", popupUuid: "popup-1").task, key: "popupUuid") == "popup-1")
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
