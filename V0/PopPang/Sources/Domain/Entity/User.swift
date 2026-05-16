//
//  User.swift
//  PopPang
//
//  Created by 김동현 on 9/19/25.
//

import Foundation

struct User {
    let userUuid: String
    let uid: String
    let provider: String
    let email: String?
    var nickname: String?
    let role: String
    var isAlerted: Bool
    var fcmToken: String?
    var alertKeywordList: [String]?
    var recommendList: [Int]?
}

extension User {
    func toDTO() -> UserDTO {
        return UserDTO(userUuid: userUuid,
                       uid: uid,
                       provider: provider,
                       email: email,
                       nickname: nickname,
                       role: role,
                       isAlerted: isAlerted,
                       fcmToken: fcmToken,
                       alertKeywordList: alertKeywordList,
                       recommendList: recommendList)
    }
}

extension User {
    static let adminUser = User(userUuid: "4c3b9a55-f4ee-42cc-9bd2-82a5c811db13",
                                uid: "67890",
                                provider: "kakao",
                                email: "john@example.com",
                                nickname: "UI테스터",
                                role: "admin",
                                isAlerted: false,
                                fcmToken: "",
                                alertKeywordList: ["팝업스토어", "카페"],
                                recommendList: [1, 2])
}
