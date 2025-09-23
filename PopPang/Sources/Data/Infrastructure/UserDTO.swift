//
//  UserDTO.swift
//  PopPang
//
//  Created by 김동현 on 9/22/25.
//

import Foundation

struct UserDTO: Codable {
    let uid: String
    let email: String?
    let nickname: String?
    let role: String
    let provider: String
    let keywords: [String]?
    let recommands: [String]?
}

extension UserDTO {
    func toModel() -> User {
        return User(uid: uid,
                    email: email,
                    nickname: nickname,
                    role: role,
                    provider: provider,
                    keywords: keywords,
                    recommands: recommands)
    }
}
