import Core
import Foundation
import Moya

public enum UserAPI {
    case checkNickname(nickname: String)
    case updateNickname(userUuid: String, newNickname: String)
    case autoLogin(userUuid: String)
    case getRecommendList
    case hardDeleteUser(userUuid: String)
    case getAlertKeywordList(userUuid: String)
    case addAlertKeyword(userUuid: String, newAlertKeyword: String)
    case removeAlertKeyword(userUuid: String, deleteAlertKeyword: String)
    case alertStatus(userUuid: String, isAlerted: Bool)
    case checkFcmToken(userUuid: String, fcmToken: String)
    case updateFcmToken(userUuid: String, newFcmToken: String)
}

extension UserAPI: BaseAPI {
    public var path: String {
        switch self {
        case .checkNickname:
            return "/user/nickname/duplicated"
        case .updateNickname(let userUuid, _):
            return "/user/\(userUuid)"
        case .autoLogin:
            return "/auth/autoLogin"
        case .getRecommendList:
            return "/recommend"
        case .hardDeleteUser(let userUuid):
            return "/user/\(userUuid)/hard-delete"
        case .getAlertKeywordList, .addAlertKeyword, .removeAlertKeyword:
            return "/alert-keyword"
        case .alertStatus(let userUuid, _):
            return "/user/\(userUuid)/alert-status"
        case .checkFcmToken(let userUuid, _):
            return "/user/\(userUuid)/fcm-token/duplicate-check"
        case .updateFcmToken(let userUuid, _):
            return "/user/\(userUuid)/fcm-token/update"
        }
    }

    public var method: Moya.Method {
        switch self {
        case .checkNickname, .getRecommendList, .getAlertKeywordList, .checkFcmToken:
            return .get
        case .autoLogin, .addAlertKeyword:
            return .post
        case .updateNickname, .alertStatus:
            return .patch
        case .updateFcmToken:
            return .put
        case .hardDeleteUser, .removeAlertKeyword:
            return .delete
        }
    }

    public var task: Task {
        switch self {
        case .checkNickname(let nickname):
            return .requestParameters(parameters: ["nickname": nickname], encoding: URLEncoding.queryString)
        case .updateNickname(_, let newNickname):
            return .requestParameters(parameters: ["nickname": newNickname], encoding: JSONEncoding.default)
        case .autoLogin(let userUuid):
            return .requestJSONEncodable(["userUuid": userUuid])
        case .getRecommendList, .hardDeleteUser:
            return .requestPlain
        case .getAlertKeywordList(let userUuid):
            return .requestParameters(parameters: ["userUuid": userUuid], encoding: URLEncoding.queryString)
        case .addAlertKeyword(let userUuid, let newAlertKeyword):
            return .requestParameters(
                parameters: [
                    "userUuid": userUuid,
                    "newAlertKeyword": newAlertKeyword,
                ],
                encoding: JSONEncoding.default
            )
        case .removeAlertKeyword(let userUuid, let deleteAlertKeyword):
            return .requestParameters(
                parameters: [
                    "userUuid": userUuid,
                    "deleteAlertKeyword": deleteAlertKeyword,
                ],
                encoding: JSONEncoding.default
            )
        case .alertStatus(_, let isAlerted):
            return .requestParameters(parameters: ["isAlerted": isAlerted], encoding: JSONEncoding.default)
        case .checkFcmToken(_, let fcmToken):
            return .requestParameters(parameters: ["fcmToken": fcmToken], encoding: URLEncoding.queryString)
        case .updateFcmToken(_, let newFcmToken):
            return .requestParameters(parameters: ["fcmToken": newFcmToken], encoding: JSONEncoding.default)
        }
    }
}
