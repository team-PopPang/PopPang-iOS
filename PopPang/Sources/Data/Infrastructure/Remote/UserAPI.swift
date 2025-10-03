//
//  UserAPI.swift
//  PopPang
//
//  Created by 김동현 on 10/3/25.
//

import Moya
import Foundation

enum UserAPI {
    case nicknameDuplicate(nickname: String)
}

extension UserAPI: TargetType {
    var baseURL: URL { URL(string: Constants.PopPangAPI.apiURL)! }
    
    var path: String {
        switch self {
        case .nicknameDuplicate: return "/auth/nicknameDuplicate"
        }
    }
    
    var method: Moya.Method {
        switch self {
        case .nicknameDuplicate: return .get
        }
    }
    
    var task: Moya.Task {
        switch self {
        case .nicknameDuplicate(let nickname):
            return .requestParameters(parameters: ["nickname": nickname],
                                      encoding: URLEncoding.queryString)
        }
    }
    
    var headers: [String : String]? {
        [
            "Content-Type": "application/json",
            "accept": "application/json"
        ]
    }
}
