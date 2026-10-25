import Core
import Foundation
import Moya

/// 이미 가입한 사용자의 서버 데이터를 보정하는 V2 API
public enum MigrationAPI {
    /// `PATCH /api/v2/user/signup-os`. 서버가 V2 마이그레이션 명세(`cc55e51`) 뒤에 추가했다(2026-10-25).
    ///
    /// 가입 OS가 비어 있으면 저장하고, 이미 값이 있으면 유지한다. 성공 응답은 빈 본문이다.
    case fillSignupOs
}

extension MigrationAPI: BaseAPI {
    public var apiVersion: APIVersion {
        .v2
    }

    public var authorization: APIAuthorization {
        .access
    }

    public var path: String {
        switch self {
        case .fillSignupOs:
            return "/user/signup-os"
        }
    }

    public var method: Moya.Method {
        switch self {
        case .fillSignupOs:
            return .patch
        }
    }

    public var task: Task {
        switch self {
        case .fillSignupOs:
            return .requestJSONEncodable(["signupOs": "IOS"])
        }
    }
}
