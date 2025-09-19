//
//  User.swift
//  PopPang
//
//  Created by 김동현 on 9/19/25.
//

import Foundation

struct User {
    let uid: String
    let nickname: String?
    let role: String
    let provider: String
    
    var isNewUser: Bool {
        return nickname == nil
    }
}

struct UserDTO: Codable {
    let uid: String
    let nickname: String?
    let role: String
    let provider: String
}

extension UserDTO {
    func toModel() -> User {
        return User(uid: uid, nickname: nickname, role: role, provider: provider)
    }
}
