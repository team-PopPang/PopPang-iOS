//
//  AppleAuthAPI.swift
//  PopPang
//
//  Created by 김동현 on 10/3/25.
//

import Moya
import Foundation

enum AppleAuthAPI {
    case loginWithEmail(authCode: String, email: String)
    case login(authCode: String)
    case signup(userDto: UserDTO)
}

extension AppleAuthAPI: TargetType {
    var baseURL: URL { URL(string: Constants.PopPangAPI.apiURL)! }
    
    var path: String {
        switch self {
        case .loginWithEmail: return "/auth/apple/mobile/login"
        case .login: return "/auth/apple/mobile/login"
        case .signup: return "/auth/apple/signup"
        }
    }
    
    var method: Moya.Method {
        switch self {
        case .loginWithEmail: return .post
        case .login: return .post
        case .signup: return .post
        }
    }
    
    var task: Task {
        switch self {
        case .loginWithEmail(let authCode, let email):
            return .requestJSONEncodable([
                "auth_code": authCode,
                "email": email
            ])
        case .login(let authCode):
            return .requestJSONEncodable(["auth_code": authCode])
        case .signup(let userDto):
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
