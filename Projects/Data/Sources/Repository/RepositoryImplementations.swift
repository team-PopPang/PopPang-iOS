import AuthenticationServices
import Core
import Domain
import Foundation
import GoogleSignIn
import KakaoSDKAuth
import KakaoSDKUser
import Moya
import UIKit

public final class AdminRepositoryImpl: AdminRepositoryProtocol {
    public init() {}

    public func deactivatePopup(userUuid: String, popupUuid: String) async throws {
        try await adminProvider.asyncRequestVoid(.deactivatePopup(userUuid: userUuid, popupUuid: popupUuid))
    }

    private var adminProvider: MoyaProvider<AdminAPI> {
        NetworkProvider.shared.makeProvider()
    }
}

public final class AppleAuthRepositoryImpl: AppleAuthRepositoryProtocol {
    public init() {}

    public func appleLogin(authorization: ASAuthorization) async throws -> Domain.User {
        guard
            let credential = authorization.credential as? ASAuthorizationAppleIDCredential,
            let authCodeData = credential.authorizationCode,
            let authCode = String(data: authCodeData, encoding: .utf8)
        else {
            throw AppleAuthRepositoryError.authCodeNotFound
        }

        if let email = credential.email {
            return try await appleProvider.asyncRequest(
                .loginWithEmail(authCode: authCode, email: email),
                decodeTo: UserDTO.self
            ).toModel()
        } else {
            return try await appleProvider.asyncRequest(.login(authCode: authCode), decodeTo: UserDTO.self).toModel()
        }
    }

    public func appleRegister(user: Domain.User) async throws -> Domain.User {
        try await appleProvider.asyncRequest(.signup(userDto: user.toDTO()), decodeTo: UserDTO.self).toModel()
    }

    private var appleProvider: MoyaProvider<AppleAuthAPI> {
        NetworkProvider.shared.makeProvider()
    }
}

public final class GoogleAuthRepositoryImpl: GoogleAuthRepositoryProtocol {
    public init() {}

    @MainActor
    public func googleLogin() async throws -> Domain.User {
        let presentingVC = try await MainActor.run {
            guard
                let vc = (UIApplication.shared.connectedScenes.first as? UIWindowScene)?
                    .windows
                    .first?
                    .rootViewController
            else {
                throw GoogleAuthError.noRootViewController
            }
            return vc
        }

        let result = try await GIDSignIn.sharedInstance.signIn(withPresenting: presentingVC)
        let user = result.user
        let responseDTO = GoogleResponseDTO(
            oauthId: user.userID ?? "",
            idToken: user.idToken?.tokenString ?? ""
        )

        return try await googleProvider.asyncRequest(.login(idToken: responseDTO.idToken), decodeTo: UserDTO.self).toModel()
    }

    public func googleRegister(user: Domain.User) async throws -> Domain.User {
        try await googleProvider.asyncRequest(.signup(userDTO: user.toDTO()), decodeTo: UserDTO.self).toModel()
    }

    private var googleProvider: MoyaProvider<GoogleAuthAPI> {
        NetworkProvider.shared.makeProvider()
    }
}

public final class KakaoAuthRepositoryImpl: KakaoAuthRepositoryProtocol {
    public init() {}

    public func kakaoLogin() async throws -> Domain.User {
        let oauthToken: OAuthToken

        if UserApi.isKakaoTalkLoginAvailable() {
            oauthToken = try await handleWithKakaoApp()
        } else {
            oauthToken = try await handleWithKakaoWeb()
        }

        return try await kakaoProvider.asyncRequest(
            .login(accessToken: oauthToken.accessToken),
            decodeTo: UserDTO.self
        ).toModel()
    }

    public func kakaoRegister(user: Domain.User) async throws -> Domain.User {
        try await kakaoProvider.asyncRequest(.signup(userDTO: user.toDTO()), decodeTo: UserDTO.self).toModel()
    }

    @MainActor
    private func handleWithKakaoApp() async throws -> OAuthToken {
        try await withCheckedThrowingContinuation { continuation in
            UserApi.shared.loginWithKakaoTalk { oauthToken, error in
                if let error {
                    continuation.resume(throwing: error)
                } else if let oauthToken {
                    continuation.resume(returning: oauthToken)
                } else {
                    continuation.resume(throwing: KakaoAuthRepositoryError.tokenNotFound)
                }
            }
        }
    }

    @MainActor
    private func handleWithKakaoWeb() async throws -> OAuthToken {
        try await withCheckedThrowingContinuation { continuation in
            UserApi.shared.loginWithKakaoAccount { oauthToken, error in
                if let error {
                    continuation.resume(throwing: error)
                } else if let oauthToken {
                    continuation.resume(returning: oauthToken)
                } else {
                    continuation.resume(throwing: KakaoAuthRepositoryError.tokenNotFound)
                }
            }
        }
    }

    private var kakaoProvider: MoyaProvider<KakaoAuthAPI> {
        NetworkProvider.shared.makeProvider()
    }
}

public final class PopupRepositoryImpl: PopupRepositoryProtocol {
    public init() {}

    public func getPopupList() async throws -> [Popup] {
        try await popupProvider.asyncRequest(.getPopupList, decodeTo: [PopupDTO].self).map { $0.toEntity() }
    }

    public func getUpcomingPopupList() async throws -> [Popup] {
        try await popupProvider.asyncRequest(.getUpcomingPopupList, decodeTo: [PopupDTO].self).map { $0.toEntity() }
    }

    public func getInProgressPopupList() async throws -> [Popup] {
        try await popupProvider.asyncRequest(.getInProgressPopupList, decodeTo: [PopupDTO].self).map { $0.toEntity() }
    }

    public func getFavoriteList(userUuid: String) async throws -> [Popup] {
        try await popupProvider.asyncRequest(.getFavoriteList(userUuid: userUuid), decodeTo: [PopupDTO].self).map { $0.toEntity() }
    }

    public func searchPopupList(searchText: String) async throws -> [Popup] {
        try await popupProvider.asyncRequest(.searchPopupList(searchText: searchText), decodeTo: [PopupDTO].self).map { $0.toEntity() }
    }

    public func getRandomPopupList() async throws -> [Popup] {
        try await popupProvider.asyncRequest(.getRandomPopupList, decodeTo: [PopupDTO].self).map { $0.toEntity() }
    }

    public func getPersonalPopupList(userUuid: String) async throws -> [Popup] {
        try await popupProvider.asyncRequest(.getPersonalPopupList(userUuid: userUuid), decodeTo: [PopupDTO].self).map { $0.toEntity() }
    }

    public func getPersonalUseerRecommendPopupList(userUuid: String) async throws -> [Popup] {
        try await popupProvider.asyncRequest(
            .getPersonalUseerRecommendPopupList(userUuid: userUuid),
            decodeTo: [PopupDTO].self
        ).map { $0.toEntity() }
    }

    public func getPersonalUpcomingPopupList(userUuid: String) async throws -> [Popup] {
        try await popupProvider.asyncRequest(
            .getPersonalUpcomingPopupList(userUuid: userUuid),
            decodeTo: [PopupDTO].self
        ).map { $0.toEntity() }
    }

    public func getPersonalFilteredPopupList(
        userUuid: String,
        region: String,
        district: String,
        homeSortStandard: String
    ) async throws -> [Popup] {
        try await popupProvider.asyncRequest(
            .getPersonalFilteredPopupList(
                userUuid: userUuid,
                region: region,
                district: district,
                homeSortStandard: homeSortStandard
            ),
            decodeTo: [PopupDTO].self
        ).map { $0.toEntity() }
    }

    public func getPersonalSearchPopupList(userUuid: String, searchText: String) async throws -> [Popup] {
        try await popupProvider.asyncRequest(
            .getPersonalSearchPopupList(userUuid: userUuid, searchText: searchText),
            decodeTo: [PopupDTO].self
        ).map { $0.toEntity() }
    }

    public func getPersonalMapFilteredPopupList(
        userUuid: String,
        region: String,
        district: String,
        latitude: Double?,
        longitude: Double?,
        mapSortStandard: String
    ) async throws -> [Popup] {
        try await popupProvider.asyncRequest(
            .getPersonalMapFilteredPopupList(
                userUuid: userUuid,
                region: region,
                district: district,
                latitude: latitude,
                longitude: longitude,
                mapSortStandard: mapSortStandard
            ),
            decodeTo: [PopupDTO].self
        ).map { $0.toEntity() }
    }

    public func getPersonalRelatedPopupList(userUuid: String, popupUuid: String) async throws -> [Popup] {
        try await popupProvider.asyncRequest(
            .getPersonalRelatedPopupList(userUuid: userUuid, popupUuid: popupUuid),
            decodeTo: [PopupDTO].self
        ).map { $0.toEntity() }
    }

    public func getPersonalRandomPopupList(userUuid: String) async throws -> [Popup] {
        try await popupProvider.asyncRequest(
            .getPersonalRandomPopupList(userUuid: userUuid),
            decodeTo: [PopupDTO].self
        ).map { $0.toEntity() }
    }

    public func getAlertPopupList(userUuid: String) async throws -> [Popup] {
        try await popupProvider.asyncRequest(.getAlertPopupList(userUuid: userUuid), decodeTo: [PopupDTO].self).map { $0.toEntity() }
    }

    public func removeAlertPopup(userUuid: String, popupUuid: String) async throws {
        try await popupProvider.asyncRequestVoid(.removeAlertPopup(userUuid: userUuid, popupUuid: popupUuid))
    }

    public func increaseViewCount(popupUuid: String) async throws {
        try await popupProvider.asyncRequestVoid(.increaseViewCount(popupUuid: popupUuid))
    }

    public func addFavorite(userUuid: String, popupUuid: String) async throws {
        try await popupProvider.asyncRequestVoid(.addFavorite(userUuid: userUuid, popupUuid: popupUuid))
    }

    public func removeFavorite(userUuid: String, popupUuid: String) async throws {
        try await popupProvider.asyncRequestVoid(.removeFavorite(userUuid: userUuid, popupUuid: popupUuid))
    }

    public func getRegionList() async throws -> [RegionList] {
        try await popupProvider.asyncRequest(.getRegionList, decodeTo: [RegionListDTO].self).map { $0.toEntity() }
    }

    public func getPopularRecommendList() async throws -> [Recommend] {
        try await popupProvider.asyncRequest(.getPopularRecommendList, decodeTo: [RecommendListDTO].self).map { $0.toModel() }
    }

    public func getPopularRecommendPopupList(userUuid: String, recommendId: Int) async throws -> [Popup] {
        try await popupProvider.asyncRequest(
            .getPopularRecommendPopupList(userUuid: userUuid, recommendId: recommendId),
            decodeTo: [PopupDTO].self
        ).map { $0.toEntity() }
    }

    private var popupProvider: MoyaProvider<PopupAPI> {
        NetworkProvider.shared.makeProvider()
    }
}

public final class UserRepositoryImpl: UserRepositoryProtocol {
    public init() {}

    public func checkNickname(nickname: String) async throws -> Bool {
        do {
            let response = try await userProvider.asyncRequest(
                .checkNickname(nickname: nickname),
                decodeTo: CheckNicknameDTO.self
            )
            return response.isDuplicated
        } catch {
            switch error {
            case is DecodingError:
                throw UserRepositoryError.decodingError
            default:
                throw UserRepositoryError.unknown(error)
            }
        }
    }

    public func autoLogin(userUuid: String) async throws -> Domain.User {
        try await userProvider.asyncRequest(.autoLogin(userUuid: userUuid), decodeTo: UserDTO.self).toModel()
    }

    public func getRecommandList() async throws -> [Recommend] {
        try await userProvider.asyncRequest(.getRecommendList, decodeTo: [RecommendListDTO].self).map { $0.toModel() }
    }

    public func hardDeleteUser(userUuid: String) async throws {
        try await userProvider.asyncRequestVoid(.hardDeleteUser(userUuid: userUuid))
    }

    public func getAlertKeywordList(userUuid: String) async throws -> [Keyword] {
        try await userProvider.asyncRequest(
            .getAlertKeywordList(userUuid: userUuid),
            decodeTo: [KeywordDTO].self
        ).map { $0.toModel() }
    }

    public func addAlertKeyword(userUuid: String, alertKeyword: String) async throws {
        try await userProvider.asyncRequestVoid(
            .addAlertKeyword(userUuid: userUuid, newAlertKeyword: alertKeyword)
        )
    }

    public func removeAlertKeyword(userUuid: String, alertKeyword: String) async throws {
        try await userProvider.asyncRequestVoid(
            .removeAlertKeyword(userUuid: userUuid, deleteAlertKeyword: alertKeyword)
        )
    }

    public func alertStatus(userUuid: String, isAlerted: Bool) async throws {
        try await userProvider.asyncRequestVoid(.alertStatus(userUuid: userUuid, isAlerted: isAlerted))
    }

    public func updateNickname(userUuid: String, newNickname: String) async throws {
        try await userProvider.asyncRequestVoid(.updateNickname(userUuid: userUuid, newNickname: newNickname))
    }

    public func checkFcmToken(userUuid: String, fcmToken: String) async throws -> Bool {
        try await userProvider.asyncRequest(
            .checkFcmToken(userUuid: userUuid, fcmToken: fcmToken),
            decodeTo: Bool.self
        )
    }

    public func updateFcmToken(userUuid: String, fcmToken: String) async throws {
        try await userProvider.asyncRequestVoid(
            .updateFcmToken(userUuid: userUuid, newFcmToken: fcmToken)
        )
    }

    private var userProvider: MoyaProvider<UserAPI> {
        NetworkProvider.shared.makeProvider()
    }
}
