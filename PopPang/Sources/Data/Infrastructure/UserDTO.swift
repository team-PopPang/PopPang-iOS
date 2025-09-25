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

extension UserDTO {
    static let adminUser = UserDTO(uid: "67890",
                                email: "john@example.com",
                                nickname: "JohnDoe",
                                role: "user",
                                provider: "kakao",
                                keywords: ["팝업스토어", "카페"],
                                recommands: ["패션", "굿즈"])
}
