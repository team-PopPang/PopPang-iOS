//
//  User.swift
//  PopPang
//
//  Created by 김동현 on 9/19/25.
//

import Foundation

struct User {
    let uid: String
    let email: String?
    var nickname: String?
    let role: String
    let provider: String
    var keywords: [String]?
    var recommands: [String]?
    
    var isNewUser: Bool {
        return nickname == nil
    }
}

extension User {
    static let adminUser = User(uid: "67890",
                                email: "john@example.com",
                                nickname: "JohnDoe",
                                role: "user",
                                provider: "kakao",
                                keywords: ["팝업스토어", "카페"],
                                recommands: ["패션", "굿즈"])
}
