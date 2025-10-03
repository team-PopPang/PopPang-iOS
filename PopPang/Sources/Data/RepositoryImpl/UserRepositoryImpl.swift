//
//  UserRepositoryImpl.swift
//  PopPang
//
//  Created by 김동현 on 10/3/25.
//

import Foundation

struct CheckNicknameDTO: Decodable {
    let isDuplicated: Bool
}

final class UserRepositoryImpl: UserRepositoryProtocol {
    func checkNickname(nickname: String) async throws -> Bool {
        do {
            let response =  try await NetworkProvider.shared.userProvider.asyncRequest(.checkNickname(nickname: nickname),
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
    
    func autoLogin(uid: String) async throws -> User {
        let userDTO = try await NetworkProvider.shared.userProvider.asyncRequest(.autoLogin(uid: uid),
                                                                                 decodeTo: UserDTO.self)
        return userDTO.toModel()
    }
}
