//
//  UserDTO.swift
//  PopPang
//
//  Created by 김동현 on 9/22/25.
//

import Foundation

struct UserDTO: Codable {
    let uid: String
    let provider: String
    let email: String?
    let nickname: String?
    let role: String
    let isAlerted: Bool
    let fcmToken: String?
    // let alertList: [String]?
    let keywordList: [String]?
    let recommandList: [Int]?
}

extension UserDTO {
    func toModel() -> User {
        return User(uid: uid,
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

extension UserDTO {
    static let adminUser = UserDTO(uid: "0000",
                                   provider: "kakao",
                                   email: "index@example.com",
                                   nickname: "김동현",
                                   role: "user",
                                   isAlerted: false,
                                   fcmToken: "",
                                   keywordList: ["팝업스토어", "카페"],
                                   recommandList: [1, 2])
}
