//
//  KakaoAuthAPI.swift
//  PopPang
//
//  Created by 김동현 on 10/3/25.
//

import Moya
import Foundation

enum KakaoAuthAPI {
    case login(accessToken: String)
    case signup(userDto: UserDTO)
}

extension KakaoAuthAPI: TargetType {
    var baseURL: URL { URL(string: Constants.PopPangAPI.apiURL)! }
    
    var path: String {
        switch self {
        case .login:
            return "/auth/kakao/mobile/login"
        case .signup: return "/auth/kakao/signup"
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
        case .login(let accessToken):
            return .requestJSONEncodable(["access_token": accessToken])
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
