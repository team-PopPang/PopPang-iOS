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
    case getKeywordList
}

extension UserAPI: TargetType {
    var baseURL: URL { URL(string: Constants.PopPangAPI.apiURL)! }
    
    var path: String {
        switch self {
        case .checkNickname: return "/user/nickname/duplicated"
        case .autoLogin: return "/auth/autoLogin"
        case .getRecommandList: return "/recommend"
        case .getKeywordList: return "/keyword"
        }
    }
    
    var method: Moya.Method {
        switch self {
        case .checkNickname: return .get
        case .autoLogin: return .post
        case .getRecommandList: return .get
        case .getKeywordList: return .get
        }
    }
    
    var task: Moya.Task {
        switch self {
        case .checkNickname(let nickname):
            return .requestParameters(parameters: ["nickname": nickname],
                                      encoding: URLEncoding.queryString)
        case .autoLogin(let uid):
            return .requestJSONEncodable(["uid": uid])

        case .getRecommandList:
            return .requestPlain
            
        case .getKeywordList:
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
