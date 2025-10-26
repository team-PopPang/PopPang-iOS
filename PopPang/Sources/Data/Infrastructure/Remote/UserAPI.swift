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
    case updateNickname(userUuid: String, newNickname: String)
    case autoLogin(userUuid: String)
    case getRecommendList
    case getAlertKeywordList(userUuid: String)
    case addAlertKeyword(userUuid: String, newAlertKeyword: String)
    case removeAlertKeyword(userUuid: String, deleteAlertKeyword: String)
}

extension UserAPI: TargetType {
    var baseURL: URL { URL(string: Constants.PopPangAPI.apiURL)! }
    
    var path: String {
        switch self {
        case .checkNickname: return "/user/nickname/duplicated"
        case .updateNickname(let userUuid, _): return "/user/\(userUuid)"
        case .autoLogin: return "/auth/autoLogin"
        case .getRecommendList: return "/recommend"
        case .getAlertKeywordList: return "/alert-keyword"
        case .addAlertKeyword: return "/alert-keyword"
        case .removeAlertKeyword: return "/alert-keyword"
        }
    }
    
    var method: Moya.Method {
        switch self {
        case .checkNickname: return .get
        case .updateNickname: return .patch
        case .autoLogin: return .post
        case .getRecommendList: return .get
        case .getAlertKeywordList: return .get
        case .addAlertKeyword: return .post
        case .removeAlertKeyword: return .delete
        }
    }
    
    var task: Moya.Task {
        switch self {
        case .checkNickname(let nickname):
            return .requestParameters(parameters: ["nickname": nickname],
                                      encoding: URLEncoding.queryString)
            
        case .updateNickname(_, let newNickname):
            return .requestParameters(parameters: ["nickname": newNickname],
                                      encoding: JSONEncoding.default)
        case .autoLogin(let userUuid):
            return .requestJSONEncodable(["userUuid": userUuid])

        case .getRecommendList:
            return .requestPlain
            
        case .getAlertKeywordList(let userUuid):
            return .requestParameters(parameters: ["userUuid": userUuid],
                                      encoding: URLEncoding.queryString)
        case .addAlertKeyword(let userUuid, let newAlertKeyword):
            return .requestParameters(parameters: ["userUuid": userUuid,
                                                   "newAlertKeyword": newAlertKeyword],
                                      encoding: JSONEncoding.default)
        case .removeAlertKeyword(let userUuid, let deleteAlertKeyword):
            return .requestParameters(parameters: ["userUuid": userUuid,
                                                   "deleteAlertKeyword": deleteAlertKeyword],
                                      encoding: JSONEncoding.default)
        }
    }
    
    var headers: [String : String]? {
        [
            "Content-Type": "application/json",
            "accept": "application/json"
        ]
    }
}
