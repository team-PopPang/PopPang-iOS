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
    let nickname: String?
    let role: String
    let provider: String
    
    var isNewUser: Bool {
        return nickname == nil
    }
}

