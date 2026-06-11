import Core
import Domain
import Foundation
import Moya

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
