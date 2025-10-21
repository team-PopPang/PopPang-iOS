//
//  UserDTO.swift
//  PopPang
//
//  Created by 김동현 on 9/22/25.
//

import Foundation

struct UserDTO: Codable {
    let userUuid: String
    let uid: String
    let provider: String
    let email: String?
    let nickname: String?
    let role: String
    let isAlerted: Bool
    let fcmToken: String?
    let alertKeywordList: [String]?
    let recommendList: [Int]?
}

extension UserDTO {
    func toModel() -> User {
        return User(userUuid: userUuid,
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

extension UserDTO {
    static let adminUser = UserDTO(userUuid: "1234",
                                   uid: "0000",
                                   provider: "kakao",
                                   email: "index@example.com",
                                   nickname: "김동현",
                                   role: "user",
                                   isAlerted: false,
                                   fcmToken: "",
                                   alertKeywordList: ["팝업스토어", "카페"],
                                   recommendList: [1, 2])
}
