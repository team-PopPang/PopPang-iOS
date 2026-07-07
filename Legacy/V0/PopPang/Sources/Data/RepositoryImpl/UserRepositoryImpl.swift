//
//  UserRepositoryImpl.swift
//  PopPang
//
//  Created by 김동현 on 10/3/25.
//

import Foundation

final class UserRepositoryImpl: UserRepositoryProtocol {
    func checkNickname(nickname: String) async throws -> Bool {
        do {
            let response = try await NetworkProvider.shared.userProvider.asyncRequest(.checkNickname(nickname: nickname),
                                                                              decodeTo: CheckNicknameDTO.self)
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
    
    func autoLogin(userUuid: String) async throws -> UserDTO {
        let userDTO = try await NetworkProvider.shared.userProvider.asyncRequest(.autoLogin(userUuid: userUuid),
                                                                                 decodeTo: UserDTO.self)
        return userDTO
    }
    
    func getRecommandList() async throws -> [RecommendListDTO] {
        try await NetworkProvider.shared.userProvider.asyncRequest(.getRecommendList, decodeTo: [RecommendListDTO].self)
    }
    
    func hardDeleteUser(userUuid: String) async throws {
        try await NetworkProvider.shared.userProvider.asyncRequestVoid(.hardDeleteUser(userUuid: userUuid))
    }
    
    func getAlertKeywordList(userUuid: String) async throws -> [KeywordDTO] {
        try await NetworkProvider.shared.userProvider.asyncRequest(.getAlertKeywordList(userUuid: userUuid), decodeTo: [KeywordDTO].self)
    }

    func addAlertKeyword(userUuid: String, alertKeyword: String) async throws {
        try await NetworkProvider.shared.userProvider.asyncRequestVoid(.addAlertKeyword(userUuid: userUuid, newAlertKeyword: alertKeyword))
    }
    
    func removeAlertKeyword(userUuid: String, alertKeyword: String) async throws {
        try await NetworkProvider.shared.userProvider.asyncRequestVoid(.removeAlertKeyword(userUuid: userUuid, deleteAlertKeyword: alertKeyword))
    }
    
    func alertStatus(userUuid: String, isAlerted: Bool) async throws {
        try await NetworkProvider.shared.userProvider.asyncRequestVoid(.alertStatus(userUuid: userUuid, isAlerted: isAlerted))
    }
    
    func updateNickname(userUuid: String, newNickname: String) async throws {
        try await NetworkProvider.shared.userProvider.asyncRequestVoid(.updateNickname(userUuid: userUuid, newNickname: newNickname))
    }
    
    func checkFcmToken(userUuid: String, fcmToken: String) async throws -> Bool {
        try await NetworkProvider.shared.userProvider.asyncRequest(.checkFcmToken(userUuid: userUuid, fcmToken: fcmToken), decodeTo: Bool.self)
    }
    
    func updateFcmToken(userUuid: String, fcmToken: String) async throws {
        try await NetworkProvider.shared.userProvider.asyncRequestVoid(.updateFcmToken(userUuid: userUuid, newFcmToken: fcmToken))
    }
}
