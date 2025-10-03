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
    case signUp(userDto: UserDTO)
}

extension AppleAuthAPI: TargetType {
    var baseURL: URL { URL(string: Constants.PopPangAPI.apiURL)! }
    
    var path: String {
        switch self {
        case .login: return "/auth/apple/mobile/login"
        case .signUp: return "/auth/apple/signup"
        }
    }
    
    var method: Moya.Method {
        switch self {
        case .login: return .post
        case .signUp: return .post
        }
    }
    
    var task: Task {
        switch self {
        case .login(let authCode):
            return .requestJSONEncodable(["auth_code": authCode])
        case .signUp(let userDto):
            return .requestJSONEncodable(userDto)
        }
    }
    
    var headers: [String : String]? {
        [
            "Content-Type": "application/json",
            "accept": "application/json"
        ]
    }
}
