import AuthenticationServices
import Foundation

public protocol AdminUsecaseProtocol {
    func deactivatePopup(userUuid: String, popupUuid: String) async throws
}

public protocol AppleAuthUsecaseProtocol {
    func appleLogin(authorization: ASAuthorization) async throws -> User
    func appleRegister(user: User) async throws -> User
}

public protocol GoogleAuthUsecaseProtocol {
    func googleLogin() async throws -> User
    func googleRegister(user: User) async throws -> User
}

public protocol KakaoAuthUsecaseProtocol {
    func kakaoLogin() async throws -> User
    func kakaoRegister(user: User) async throws -> User
}

public protocol PopupUsecaseProtocol {
    func getPopupList() async throws -> [Popup]
    func getUpcomingPopupList() async throws -> [Popup]
    func getInProgressPopupList() async throws -> [Popup]
    func getFavoriteList(userUuid: String) async throws -> [Popup]
    func searchPopupList(searchText: String) async throws -> [Popup]
    func getRandomPopupList() async throws -> [Popup]

    func getPersonalPopupList(userUuid: String) async throws -> [Popup]
    func getPersonalUseerRecommendPopupList(userUuid: String) async throws -> [Popup]
    func getPersonalUpcomingPopupList(userUuid: String) async throws -> [Popup]
    func getPersonalFilteredPopupList(
        userUuid: String,
        region: String,
        district: String,
        homeSortStandard: String
    ) async throws -> [Popup]
    func getPersonalSearchPopupList(userUuid: String, searchText: String) async throws -> [Popup]
    func getPersonalMapFilteredPopupList(
        userUuid: String,
        region: String,
        district: String,
        latitude: Double?,
        longitude: Double?,
        mapSortStandard: String
    ) async throws -> [Popup]
    func getPersonalRelatedPopupList(userUuid: String, popupUuid: String) async throws -> [Popup]
    func getPersonalRandomPopupList(userUuid: String) async throws -> [Popup]

    func getAlertPopupList(userUuid: String) async throws -> [Popup]
    func removeAlertPopup(userUuid: String, popupUuid: String) async throws

    func increaseViewCount(popupUuid: String) async throws
    func addFavorite(userUuid: String, popupUuid: String) async throws
    func removeFavorite(userUuid: String, popupUuid: String) async throws

    func getRegionList() async throws -> [RegionList]
    func getPopularRecommendList() async throws -> [Recommend]
    func getPopularRecommendPopupList(userUuid: String, recommendId: Int) async throws -> [Popup]
}

public protocol UserUsecaseProtocol {
    func checkNickname(nickname: String) async throws -> Bool
    func autoLogin(userUuid: String) async throws -> User
    func getRecommandList() async throws -> [Recommend]
    func hardDeleteUser(userUuid: String) async throws
    func getAlertKeywordList(userUuid: String) async throws -> [Keyword]
    func addAlertKeyword(userUuid: String, alertKeyword: String) async throws
    func removeAlertKeyword(userUuid: String, alertKeyword: String) async throws
    func alertStatus(userUuid: String, isAlerted: Bool) async throws
    func updateNickname(userUuid: String, newNickname: String) async throws
    func checkFcmToken(userUuid: String, fcmToken: String) async throws -> Bool
    func updateFcmToken(userUuid: String, fcmToken: String) async throws
}
