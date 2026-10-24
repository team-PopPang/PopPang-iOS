import Core
import Foundation
import Moya

/// V2 내 정보 API (명세 U 묶음)
///
/// 모두 Access Token의 사용자를 처리하므로 경로에 `userUuid`를 넣지 않는다.
public enum V2UserAPI {
    /// `GET /api/v2/user/nickname/duplicated` (USER-04). 성공 응답은 `APIResponse`로 감싼 `{ isDuplicated }`다.
    case checkNickname(nickname: String)
    /// `PATCH /api/v2/user` (USER-02). 성공 응답은 빈 본문이다.
    case updateNickname(nickname: String)
    /// `PATCH /api/v2/user/alert-status` (USER-05). 성공 응답은 `APIResponse`로 감싼 `{ userUuid, isAlerted }`다.
    case alertStatus(isAlerted: Bool)
    /// `DELETE /api/v2/user` (USER-03). 성공 응답은 빈 본문이다.
    ///
    /// 명세(`cc55e51`)는 탈퇴 표시만 하는 soft delete였지만, 서버가 영구 삭제로 바꿔 배포했다(2026-10-25).
    /// 탈퇴한 뒤 같은 소셜 계정으로 다시 가입할 수 있다.
    case withdraw
}

extension V2UserAPI: BaseAPI {
    public var apiVersion: APIVersion {
        .v2
    }

    public var authorization: APIAuthorization {
        .access
    }

    public var path: String {
        switch self {
        case .checkNickname:
            return "/user/nickname/duplicated"
        case .updateNickname, .withdraw:
            return "/user"
        case .alertStatus:
            return "/user/alert-status"
        }
    }

    public var method: Moya.Method {
        switch self {
        case .checkNickname:
            return .get
        case .updateNickname, .alertStatus:
            return .patch
        case .withdraw:
            return .delete
        }
    }

    public var task: Task {
        switch self {
        case .checkNickname(let nickname):
            return .requestParameters(parameters: ["nickname": nickname], encoding: URLEncoding.queryString)
        case .updateNickname(let nickname):
            return .requestJSONEncodable(["nickname": nickname])
        case .alertStatus(let isAlerted):
            return .requestJSONEncodable(["isAlerted": isAlerted])
        case .withdraw:
            return .requestPlain
        }
    }
}
