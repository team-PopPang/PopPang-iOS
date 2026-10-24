import Core
import Foundation
import Moya

public enum UserAPI {
    case getRecommendList
    case getAlertKeywordList(userUuid: String)
    case addAlertKeyword(userUuid: String, newAlertKeyword: String)
    case removeAlertKeyword(userUuid: String, deleteAlertKeyword: String)
    case checkFcmToken(userUuid: String, fcmToken: String)
    case updateFcmToken(userUuid: String, newFcmToken: String)
}

extension UserAPI: BaseAPI {
    public var path: String {
        switch self {
        case .getRecommendList:
            return "/recommend"
        case .getAlertKeywordList, .addAlertKeyword, .removeAlertKeyword:
            return "/alert-keyword"
        case .checkFcmToken(let userUuid, _):
            return "/user/\(userUuid)/fcm-token/duplicate-check"
        case .updateFcmToken(let userUuid, _):
            return "/user/\(userUuid)/fcm-token/update"
        }
    }

    public var method: Moya.Method {
        switch self {
        case .getRecommendList, .getAlertKeywordList, .checkFcmToken:
            return .get
        case .addAlertKeyword:
            return .post
        case .updateFcmToken:
            return .put
        case .removeAlertKeyword:
            return .delete
        }
    }

    public var task: Task {
        switch self {
        case .getRecommendList:
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
        case .checkFcmToken(_, let fcmToken):
            return .requestParameters(parameters: ["fcmToken": fcmToken], encoding: URLEncoding.queryString)
        case .updateFcmToken(_, let newFcmToken):
            return .requestParameters(parameters: ["fcmToken": newFcmToken], encoding: JSONEncoding.default)
        }
    }
}
