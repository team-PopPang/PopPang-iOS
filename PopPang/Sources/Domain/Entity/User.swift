//
//  User.swift
//  PopPang
//
//  Created by 김동현 on 9/19/25.
//

import Foundation

struct User {
    let uid: String
    let provider: String
    let email: String?
    var nickname: String?
    let role: String
    let isAlerted: Bool
    let fcmToken: String?
    var keywordList: [String]?
    var recommandList: [Int]?
//    var isNewUser: Bool {
//        return nickname == nil
//    }
}

extension User {
    func toDTO() -> UserDTO {
        return UserDTO(uid: uid,
                       provider: provider,
                       email: email,
                       nickname: nickname,
                       role: role,
                       isAlerted: isAlerted,
                       fcmToken: fcmToken,
                       keywordList: keywordList,
                       recommandList: recommandList)
    }
}

extension User {
    static let adminUser = User(uid: "67890",
                                provider: "kakao",
                                email: "john@example.com",
                                nickname: "JohnDoe",
                                role: "user",
                                isAlerted: false,
                                fcmToken: "",
                                keywordList: ["팝업스토어", "카페"],
                                recommandList: [1, 2])
}
