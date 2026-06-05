import Core
import Foundation
import Moya

enum AdminAPI {
    case getPopupSubmissionList
    case createPopupSubmission(requestDTO: PopupSubmissionCreateRequestDTO)
    case deactivatePopupByUser(userUuid: String, popupUuid: String)
    case deactivatePopup(popupUuid: String)
    case updatePopupSubmissionStatus(
        submissionId: Int,
        requestDTO: PopupSubmissionStatusUpdateRequestDTO
    )
}

extension AdminAPI: BaseAPI {
    var path: String {
        switch self {
        case .getPopupSubmissionList, .createPopupSubmission:
            return "/admin/popup-submissions"
        case .deactivatePopupByUser(let userUuid, let popupUuid):
            return "/admin/user/\(userUuid)/popup/\(popupUuid)/deactivate"
        case .deactivatePopup(let popupUuid):
            return "/admin/popup/\(popupUuid)/deactivate"
        case .updatePopupSubmissionStatus(let submissionId, _):
            return "/admin/popup-submissions/\(submissionId)/status"
        }
    }

    var method: Moya.Method {
        switch self {
        case .getPopupSubmissionList:
            return .get
        case .createPopupSubmission:
            return .post
        case .deactivatePopupByUser,
             .deactivatePopup,
             .updatePopupSubmissionStatus:
            return .patch
        }
    }

    var task: Task {
        switch self {
        case .getPopupSubmissionList,
             .deactivatePopupByUser,
             .deactivatePopup:
            return .requestPlain
        case .createPopupSubmission(let requestDTO):
            return .requestJSONEncodable(requestDTO)
        case .updatePopupSubmissionStatus(_, let requestDTO):
            return .requestJSONEncodable(requestDTO)
        }
    }
}
