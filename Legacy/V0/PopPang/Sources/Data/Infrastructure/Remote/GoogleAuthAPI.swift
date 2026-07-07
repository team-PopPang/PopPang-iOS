//
//  GoogleAuthAPI.swift
//  PopPang
//
//  Created by 김동현 on 10/3/25.
//

import Moya
import Foundation

enum GoogleAuthAPI {
    case login(idToken: String)
    case signup(userDTO: UserDTO)
}

extension GoogleAuthAPI: TargetType {
    var baseURL: URL { URL(string: Constants.PopPangAPI.apiURL)! }
    
    var path: String {
        switch self {
        case .login: return "/auth/google/mobile/login"
        case .signup: return "/auth/google/signup"
        }
    }
    
    var method: Moya.Method {
        switch self {
        case .login: return .post
        case .signup: return .post
        }
    }
    
    var task: Moya.Task {
        switch self {
        case .login(let idToken):
            return .requestJSONEncodable(["id_token": idToken])
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
