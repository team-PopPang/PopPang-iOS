//
//  DummyData.swift
//  PopPang
//
//  Created by 김동현 on 11/9/25.
//

import Foundation

public enum DummyData { }

extension DummyData {
    static let userInfo = User(userUuid: "8b9777ae-c073-11f0-a84f-8e458ccf4968",
                                uid: "testUser_uid",
                                provider: "kakao",
                                email: "testUser@gmail.com",
                                nickname: "테스터",
                                role: "MEMBER",
                                isAlerted: false,
                                fcmToken: "testUser_fcm",
                                alertKeywordList: ["팝업스토어", "카페"],
                                recommendList: [1, 2])
    
    static var userInfo2 = User(userUuid: "f19b3452-3dc8-411a-9e24-1034d04ea146",
                               uid: "",
                               provider: "apple",
                               email: "",
                               nickname: "애플동현",
                               role: "member",
                               isAlerted: true)
}


