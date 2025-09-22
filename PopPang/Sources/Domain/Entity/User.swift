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
    var recommands: [String]
    
    var isNewUser: Bool {
        return nickname == nil
    }
}

