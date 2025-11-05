//
//  UserAPI.swift
//  PopPang
//
//  Created by 김동현 on 10/3/25.
//

import Moya
import Foundation

enum UserAPI {
    //  user
    case checkNickname(nickname: String)
    case updateNickname(userUuid: String, newNickname: String)
    case autoLogin(userUuid: String)
    case getRecommendList
    case hardDeleteUser(userUuid: String)
    
    // alert
    case getAlertKeywordList(userUuid: String)
    case addAlertKeyword(userUuid: String, newAlertKeyword: String)
    case removeAlertKeyword(userUuid: String, deleteAlertKeyword: String)
    case alertStatus(userUuid: String, isAlerted: Bool)
    
    // fcm
    case checkFcmToken(userUuid: String, fcmToken: String)
    case updateFcmToken(userUuid: String, newFcmToken: String)
}

extension UserAPI: TargetType {
    var baseURL: URL { URL(string: Constants.PopPangAPI.apiURL)! }
    
    var path: String {
        switch self {
        case .checkNickname: return "/user/nickname/duplicated"
        case .updateNickname(let userUuid, _): return "/user/\(userUuid)"
        case .autoLogin: return "/auth/autoLogin"
        case .getRecommendList: return "/recommend"
        case .hardDeleteUser(let userUuid): return "/user/\(userUuid)/hard-delete"
            
        case .getAlertKeywordList: return "/alert-keyword"
        case .addAlertKeyword: return "/alert-keyword"
        case .removeAlertKeyword: return "/alert-keyword"
        case .alertStatus(let userUuid, _): return "/user/\(userUuid)/alert-status"
            
        case .checkFcmToken(let userUuid, _): return "/user/\(userUuid)/fcm-token/duplicate-check"
        case .updateFcmToken(let userUuid, _): return "/user/\(userUuid)/fcm-token/update"
        }
    }
    
    var method: Moya.Method {
        switch self {
        case .checkNickname: return .get
        case .updateNickname: return .patch
        case .autoLogin: return .post
        case .getRecommendList: return .get
        case .hardDeleteUser: return .delete
            
        case .getAlertKeywordList: return .get
        case .addAlertKeyword: return .post
        case .removeAlertKeyword: return .delete
        case .alertStatus: return .patch
            
        case .checkFcmToken: return .get
        case .updateFcmToken: return .put
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
            
        case .hardDeleteUser(let userUuid):
            return .requestParameters(parameters: ["userUuid": userUuid],
                                      encoding: JSONEncoding.default)
            
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
            
        case .alertStatus(_, let isAlerted):
            return .requestParameters(parameters: ["isAlerted": isAlerted],
                                      encoding: JSONEncoding.default)
            
        case .checkFcmToken(_, let fcmToken):
            return .requestParameters(parameters: ["fcmToken": fcmToken],
                                      encoding: URLEncoding.queryString)
            
        case .updateFcmToken(_, let fcmToken):
            return .requestParameters(parameters: ["fcmToken": fcmToken],
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
