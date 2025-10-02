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
}

extension KakaoAuthAPI: TargetType {
    var baseURL: URL { URL(string: Constants.PopPangAPI.kakaoURL)! }
    
    var path: String {
        switch self {
        case .login:
            return "/auth/kakao/mobile/login"
        }
    }
    
    var method: Moya.Method {
        switch self {
        case .login:
            return .post
        }
    }
    
    var task: Moya.Task {
        switch self {
        case .login(let accessToken):
            return .requestJSONEncodable(["access_token": accessToken])
        }
    }
    
    var headers: [String : String]? {
        [
            "Content-Type": "application/json",
            "accept": "application/json"
        ]
    }
    
    
}
