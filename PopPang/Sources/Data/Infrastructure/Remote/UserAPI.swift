//
//  UserAPI.swift
//  PopPang
//
//  Created by 김동현 on 10/3/25.
//

import Moya
import Foundation

enum UserAPI {
    case checkNickname(nickname: String)
    case autoLogin(uid: String)
    case getRecommandList
}

extension UserAPI: TargetType {
    var baseURL: URL { URL(string: Constants.PopPangAPI.apiURL)! }
    
    var path: String {
        switch self {
        case .checkNickname: return "/auth/nicknameDuplicate"
        case .autoLogin: return "/auth/autoLogin"
        case .getRecommandList: return "/auth/"
        }
    }
    
    var method: Moya.Method {
        switch self {
        case .checkNickname: return .get
        case .autoLogin: return .get
        case .getRecommandList: return .get
        }
    }
    
    var task: Moya.Task {
        switch self {
        case .checkNickname(let nickname):
            return .requestParameters(parameters: ["nickname": nickname],
                                      encoding: URLEncoding.queryString)
        case .autoLogin(let uid):
            return .requestParameters(parameters: ["uid": uid],
                                      encoding: URLEncoding.queryString)
        case .getRecommandList:
            return .requestPlain
        }
    }
    
    var headers: [String : String]? {
        [
            "Content-Type": "application/json",
            "accept": "application/json"
        ]
    }
}
