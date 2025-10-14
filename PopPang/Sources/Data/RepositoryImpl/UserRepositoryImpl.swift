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
    
    func autoLogin(uuid: String) async throws -> UserDTO {
        let userDTO = try await NetworkProvider.shared.userProvider.asyncRequest(.autoLogin(uuid: uuid),
                                                                                 decodeTo: UserDTO.self)
        return userDTO
    }
    
    func getRecommandList() async throws -> [RecommandDTO] {
        do {
            let response = try await NetworkProvider.shared.userProvider.asyncRequest(.getRecommandList, decodeTo: [RecommandDTO].self)
            return response
        } catch {
            throw error
        }
    }
    
    func getAlertKeywordList(userUuid: String) async throws -> [KeywordDTO] {
        do {
            let keywordDTO = try await NetworkProvider.shared.userProvider.asyncRequest(.getAlertKeywordList(userUuid: userUuid), decodeTo: [KeywordDTO].self)
            return keywordDTO
        } catch {
            throw error
        }
    }

    func addAlertKeyword(userUuid: String, alertKeyword: String) async throws {
        try await NetworkProvider.shared.userProvider.asyncRequestVoid(.addAlertKeyword(userUuid: userUuid, newAlertKeyword: alertKeyword))
    }
    

    func removeAlertKeyword(userUuid: String, alertKeyword: String) async throws {
        try await NetworkProvider.shared.userProvider.asyncRequestVoid(.removeAlertKeyword(userUuid: userUuid, deleteAlertKeyword: alertKeyword))
    }
}
