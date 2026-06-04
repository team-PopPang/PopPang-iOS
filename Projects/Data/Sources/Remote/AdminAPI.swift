import Core
import Foundation
import Moya

public enum AdminAPI {
    case getPopupValidationList
    case validatePopup(parameters: [String: Any])
    case registerPopup(parameters: [String: Any])
    case createPopupSubmission(requestDTO: PopupSubmissionCreateRequestDTO)
    case registerPopupRecommendations(popupUuid: String, recommendIds: [Int])
    case deactivatePopup(userUuid: String, popupUuid: String)
}

extension AdminAPI: BaseAPI {
    public var path: String {
        switch self {
        case .getPopupValidationList, .validatePopup:
            return "/admin/popup-validation"
        case .registerPopup:
            return "/admin/popup"
        case .createPopupSubmission:
            return "/admin/popup-submissions"
        case .registerPopupRecommendations(let popupUuid, _):
            return "/admin/popup/\(popupUuid)/recommendations"
        case .deactivatePopup(let userUuid, let popupUuid):
            return "/admin/user/\(userUuid)/popup/\(popupUuid)/deactivate"
        }
    }

    public var method: Moya.Method {
        switch self {
        case .getPopupValidationList:
            return .get
        case .validatePopup, .registerPopup, .createPopupSubmission, .registerPopupRecommendations:
            return .post
        case .deactivatePopup:
            return .patch
        }
    }

    public var task: Task {
        switch self {
        case .getPopupValidationList, .deactivatePopup:
            return .requestPlain
        case .validatePopup(let parameters), .registerPopup(let parameters):
            return .requestParameters(parameters: parameters, encoding: JSONEncoding.default)
        case .createPopupSubmission(let requestDTO):
            return .requestJSONEncodable(requestDTO)
        case .registerPopupRecommendations(_, let recommendIds):
            return .requestParameters(parameters: ["recommendIds": recommendIds], encoding: JSONEncoding.default)
        }
    }
}
