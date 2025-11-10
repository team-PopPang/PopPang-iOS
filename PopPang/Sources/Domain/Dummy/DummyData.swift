//
//  DummyData.swift
//  PopPang
//
//  Created by 김동현 on 11/9/25.
//

import Foundation

public enum DummyData { }

extension DummyData {
    static var userInfo = User(userUuid: "f19b3452-3dc8-411a-9e24-1034d04ea146",
                               uid: "",
                               provider: "apple",
                               email: "",
                               nickname: "애플동현",
                               role: "member",
                               isAlerted: true)
}
