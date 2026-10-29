import Core
import Foundation
import Moya

/// V2 찜 API (명세 F 묶음)
///
/// Access Token의 사용자로 처리하므로 경로·본문에 `userUuid`를 넣지 않는다.
public enum V2FavoriteAPI {
    /// `GET /api/v2/favorite/popup` (FAV-04). 성공 응답은 `APIResponse`로 감싼 팝업 배열이다.
    case list
    /// `POST /api/v2/favorite` (FAV-01). 성공 응답은 본문이 없다.
    case add(popupUuid: String)
    /// `DELETE /api/v2/favorite` (FAV-02). 서버가 DELETE에도 JSON 본문을 요구한다. 성공 응답은 본문이 없다.
    case remove(popupUuid: String)
}

extension V2FavoriteAPI: BaseAPI {
    public var apiVersion: APIVersion {
        .v2
    }

    public var authorization: APIAuthorization {
        .access
    }

    public var path: String {
        switch self {
        case .list:
            return "/favorite/popup"
        case .add, .remove:
            return "/favorite"
        }
    }

    public var method: Moya.Method {
        switch self {
        case .list:
            return .get
        case .add:
            return .post
        case .remove:
            return .delete
        }
    }

    public var task: Task {
        switch self {
        case .list:
            return .requestPlain
        case .add(let popupUuid), .remove(let popupUuid):
            return .requestParameters(parameters: ["popupUuid": popupUuid], encoding: JSONEncoding.default)
        }
    }
}
