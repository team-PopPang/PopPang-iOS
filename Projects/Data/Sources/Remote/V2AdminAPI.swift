import Core
import Foundation
import Moya

/// V2 관리자 API
///
/// Access Token의 사용자가 관리자일 때만 처리한다. V1처럼 관리자 UUID를 query로 보내지 않는다.
public enum V2AdminAPI {
    /// `PATCH /api/v2/admin/popup/{popupUuid}/deactivate`. 팝업을 비활성화한다. 성공 응답은 본문이 없다.
    case deactivatePopup(popupUuid: String)
}

extension V2AdminAPI: BaseAPI {
    public var apiVersion: APIVersion {
        .v2
    }

    public var authorization: APIAuthorization {
        .access
    }

    public var path: String {
        switch self {
        case .deactivatePopup(let popupUuid):
            return "/admin/popup/\(popupUuid)/deactivate"
        }
    }

    public var method: Moya.Method {
        switch self {
        case .deactivatePopup:
            return .patch
        }
    }

    public var task: Task {
        switch self {
        case .deactivatePopup:
            return .requestPlain
        }
    }
}
