import AuthenticationServices
import Foundation

public final class AdminUsecaseImpl: AdminUsecaseProtocol {
    private let adminRepository: AdminRepositoryProtocol

    public init(adminRepository: AdminRepositoryProtocol) {
        self.adminRepository = adminRepository
    }

    public func deactivatePopup(userUuid: String, popupUuid: String) async throws {
        try await adminRepository.deactivatePopup(userUuid: userUuid, popupUuid: popupUuid)
    }
}

public final class AppleAuthUsecaseImpl: AppleAuthUsecaseProtocol {
    private let appleAuthRepository: AppleAuthRepositoryProtocol

    public init(appleAuthRepository: AppleAuthRepositoryProtocol) {
        self.appleAuthRepository = appleAuthRepository
    }

    public func appleLogin(authorization: ASAuthorization) async throws -> User {
        try await appleAuthRepository.appleLogin(authorization: authorization)
    }

    public func appleRegister(user: User) async throws -> User {
        try await appleAuthRepository.appleRegister(user: user)
    }
}

public final class GoogleAuthUsecaseImpl: GoogleAuthUsecaseProtocol {
    private let googleAuthRepository: GoogleAuthRepositoryProtocol

    public init(googleAuthRepository: GoogleAuthRepositoryProtocol) {
        self.googleAuthRepository = googleAuthRepository
    }

    public func googleLogin() async throws -> User {
        try await googleAuthRepository.googleLogin()
    }

    public func googleRegister(user: User) async throws -> User {
        try await googleAuthRepository.googleRegister(user: user)
    }
}

public final class KakaoAuthUsecaseImpl: KakaoAuthUsecaseProtocol {
    private let kakaoAuthRepository: KakaoAuthRepositoryProtocol

    public init(kakaoAuthRepository: KakaoAuthRepositoryProtocol) {
        self.kakaoAuthRepository = kakaoAuthRepository
    }

    public func kakaoLogin() async throws -> User {
        try await kakaoAuthRepository.kakaoLogin()
    }

    public func kakaoRegister(user: User) async throws -> User {
        try await kakaoAuthRepository.kakaoRegister(user: user)
    }
}

public final class PopupUsecaseImpl: PopupUsecaseProtocol {
    private let popupRepository: PopupRepositoryProtocol

    public init(popupRepository: PopupRepositoryProtocol) {
        self.popupRepository = popupRepository
    }

    public func getPopupList() async throws -> [Popup] {
        try await popupRepository.getPopupList()
    }

    public func getUpcomingPopupList() async throws -> [Popup] {
        try await popupRepository.getUpcomingPopupList()
    }

    public func getInProgressPopupList() async throws -> [Popup] {
        try await popupRepository.getInProgressPopupList()
    }

    public func getFavoriteList(userUuid: String) async throws -> [Popup] {
        try await popupRepository.getFavoriteList(userUuid: userUuid)
    }

    public func searchPopupList(searchText: String) async throws -> [Popup] {
        try await popupRepository.searchPopupList(searchText: searchText)
    }

    public func getRandomPopupList() async throws -> [Popup] {
        try await popupRepository.getRandomPopupList()
    }

    public func getPersonalPopupList(userUuid: String) async throws -> [Popup] {
        try await popupRepository.getPersonalPopupList(userUuid: userUuid)
    }

    public func getPersonalUseerRecommendPopupList(userUuid: String) async throws -> [Popup] {
        try await popupRepository.getPersonalUseerRecommendPopupList(userUuid: userUuid)
    }

    public func getPersonalUpcomingPopupList(userUuid: String) async throws -> [Popup] {
        try await popupRepository.getPersonalUpcomingPopupList(userUuid: userUuid)
    }

    public func getPersonalFilteredPopupList(
        userUuid: String,
        region: String,
        district: String,
        homeSortStandard: String
    ) async throws -> [Popup] {
        try await popupRepository.getPersonalFilteredPopupList(
            userUuid: userUuid,
            region: region,
            district: district,
            homeSortStandard: homeSortStandard
        )
    }

    public func getPersonalSearchPopupList(userUuid: String, searchText: String) async throws -> [Popup] {
        try await popupRepository.getPersonalSearchPopupList(
            userUuid: userUuid,
            searchText: searchText
        )
    }

    public func getPersonalMapFilteredPopupList(
        userUuid: String,
        region: String,
        district: String,
        latitude: Double?,
        longitude: Double?,
        mapSortStandard: String
    ) async throws -> [Popup] {
        try await popupRepository.getPersonalMapFilteredPopupList(
            userUuid: userUuid,
            region: region,
            district: district,
            latitude: latitude,
            longitude: longitude,
            mapSortStandard: mapSortStandard
        )
    }

    public func getPersonalRelatedPopupList(userUuid: String, popupUuid: String) async throws -> [Popup] {
        try await popupRepository.getPersonalRelatedPopupList(
            userUuid: userUuid,
            popupUuid: popupUuid
        )
    }

    public func getPersonalRandomPopupList(userUuid: String) async throws -> [Popup] {
        try await popupRepository.getPersonalRandomPopupList(userUuid: userUuid)
    }

    public func getAlertPopupList(userUuid: String) async throws -> [Popup] {
        try await popupRepository.getAlertPopupList(userUuid: userUuid)
    }

    public func removeAlertPopup(userUuid: String, popupUuid: String) async throws {
        try await popupRepository.removeAlertPopup(userUuid: userUuid, popupUuid: popupUuid)
    }

    public func increaseViewCount(popupUuid: String) async throws {
        try await popupRepository.increaseViewCount(popupUuid: popupUuid)
    }

    public func addFavorite(userUuid: String, popupUuid: String) async throws {
        try await popupRepository.addFavorite(userUuid: userUuid, popupUuid: popupUuid)
    }

    public func removeFavorite(userUuid: String, popupUuid: String) async throws {
        try await popupRepository.removeFavorite(userUuid: userUuid, popupUuid: popupUuid)
    }

    public func getRegionList() async throws -> [RegionList] {
        try await popupRepository.getRegionList()
    }

    public func getPopularRecommendList() async throws -> [Recommend] {
        try await popupRepository.getPopularRecommendList()
    }

    public func getPopularRecommendPopupList(userUuid: String, recommendId: Int) async throws -> [Popup] {
        try await popupRepository.getPopularRecommendPopupList(
            userUuid: userUuid,
            recommendId: recommendId
        )
    }
}

public final class UserUsecaseImpl: UserUsecaseProtocol {
    private let userRepository: UserRepositoryProtocol

    public init(userRepository: UserRepositoryProtocol) {
        self.userRepository = userRepository
    }

    public func checkNickname(nickname: String) async throws -> Bool {
        try await userRepository.checkNickname(nickname: nickname)
    }

    public func autoLogin(userUuid: String) async throws -> User {
        try await userRepository.autoLogin(userUuid: userUuid)
    }

    public func getRecommandList() async throws -> [Recommend] {
        try await userRepository.getRecommandList()
    }

    public func hardDeleteUser(userUuid: String) async throws {
        try await userRepository.hardDeleteUser(userUuid: userUuid)
    }

    public func getAlertKeywordList(userUuid: String) async throws -> [Keyword] {
        try await userRepository.getAlertKeywordList(userUuid: userUuid)
    }

    public func addAlertKeyword(userUuid: String, alertKeyword: String) async throws {
        try await userRepository.addAlertKeyword(userUuid: userUuid, alertKeyword: alertKeyword)
    }

    public func removeAlertKeyword(userUuid: String, alertKeyword: String) async throws {
        try await userRepository.removeAlertKeyword(userUuid: userUuid, alertKeyword: alertKeyword)
    }

    public func alertStatus(userUuid: String, isAlerted: Bool) async throws {
        try await userRepository.alertStatus(userUuid: userUuid, isAlerted: isAlerted)
    }

    public func updateNickname(userUuid: String, newNickname: String) async throws {
        try await userRepository.updateNickname(userUuid: userUuid, newNickname: newNickname)
    }

    public func checkFcmToken(userUuid: String, fcmToken: String) async throws -> Bool {
        try await userRepository.checkFcmToken(userUuid: userUuid, fcmToken: fcmToken)
    }

    public func updateFcmToken(userUuid: String, fcmToken: String) async throws {
        try await userRepository.updateFcmToken(userUuid: userUuid, fcmToken: fcmToken)
    }
}
