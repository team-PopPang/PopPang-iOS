//
//  AppleAuthAPI.swift
//  PopPang
//
//  Created by 김동현 on 10/3/25.
//

import Moya
import Foundation

enum AppleAuthAPI {
    case login(authCode: String)
}

extension AppleAuthAPI: TargetType {
    var baseURL: URL { URL(string: Constants.PopPangAPI.appleURL)! }
    
    var path: String {
        switch self {
        case .login: return "/auth/apple/mobile/login"
        }
    }
    
    var method: Moya.Method {
        switch self {
        case .login: return .post
        }
    }
    
    var task: Task {
        switch self {
        case .login(let authCode):
            return .requestJSONEncodable(["auth_code": authCode])
        }
    }
    
    var headers: [String : String]? {
        [
            "Content-Type": "application/json",
            "accept": "application/json"
        ]
    }
}
