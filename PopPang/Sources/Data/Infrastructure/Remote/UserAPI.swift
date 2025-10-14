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
    case autoLogin(uuid: String)
    case getRecommandList
    case getAlertKeywordList(uuid: String)
}

extension UserAPI: TargetType {
    var baseURL: URL { URL(string: Constants.PopPangAPI.apiURL)! }
    
    var path: String {
        switch self {
        case .checkNickname: return "/user/nickname/duplicated"
        case .autoLogin: return "/auth/autoLogin"
        case .getRecommandList: return "/recommend"
        case .getAlertKeywordList: return "/alert-keyword"
        }
    }
    
    var method: Moya.Method {
        switch self {
        case .checkNickname: return .get
        case .autoLogin: return .post
        case .getRecommandList: return .get
        case .getAlertKeywordList: return .get
        }
    }
    
    var task: Moya.Task {
        switch self {
        case .checkNickname(let nickname):
            return .requestParameters(parameters: ["nickname": nickname],
                                      encoding: URLEncoding.queryString)
        case .autoLogin(let uuid):
            return .requestJSONEncodable(["uuid": uuid])

        case .getRecommandList:
            return .requestPlain
            
        case .getAlertKeywordList(let uuid):
            return .requestParameters(parameters: ["userUuid": uuid],
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
