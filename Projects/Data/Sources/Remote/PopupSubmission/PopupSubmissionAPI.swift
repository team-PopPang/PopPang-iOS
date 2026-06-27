import Core
import Foundation
import Moya

enum PopupSubmissionAPI {
    case createPopupSubmission(requestDTO: PopupSubmissionCreateRequestDTO)
    case getPopupSubmissionList(adminUuid: String, status: String)
    case getPopupSubmissionDetail(adminUuid: String, submissionId: Int)
    case updatePopupSubmission(adminUuid: String, submissionId: Int, requestDTO: PopupSubmissionAdminUpdateRequestDTO)
}

extension PopupSubmissionAPI: BaseAPI {
    var path: String {
        switch self {
        case .createPopupSubmission:
            return "/popup-submissions"
        case .getPopupSubmissionList:
            return "/admin/popup-submissions"
        case .getPopupSubmissionDetail(_, let submissionId),
             .updatePopupSubmission(_, let submissionId, _):
            return "/admin/popup-submissions/\(submissionId)"
        }
    }

    var method: Moya.Method {
        switch self {
        case .createPopupSubmission:
            return .post
        case .getPopupSubmissionList,
             .getPopupSubmissionDetail:
            return .get
        case .updatePopupSubmission:
            return .put
        }
    }

    var task: Task {
        switch self {
        case .createPopupSubmission(let requestDTO):
            return .requestJSONEncodable(requestDTO)

        case .getPopupSubmissionList(let adminUuid, let status):
            return .requestParameters(
                parameters: [
                    "uuid": adminUuid,
                    "status": status,
                ],
                encoding: URLEncoding.queryString
            )

        case .getPopupSubmissionDetail(let adminUuid, _):
            return .requestParameters(
                parameters: ["uuid": adminUuid],
                encoding: URLEncoding.queryString
            )

        case let .updatePopupSubmission(adminUuid, _, requestDTO):
            return .requestCompositeParameters(
                bodyParameters: requestDTO.dictionaryValue,
                bodyEncoding: JSONEncoding.default,
                urlParameters: ["uuid": adminUuid]
            )
        }
    }
}

private extension PopupSubmissionAdminUpdateRequestDTO {
    var dictionaryValue: [String: Any] {
        let data = (try? JSONEncoder().encode(self)) ?? Data()
        let object = try? JSONSerialization.jsonObject(with: data)
        return object as? [String: Any] ?? [:]
    }
}
