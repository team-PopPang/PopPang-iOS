import Core
import Foundation
import Moya

/// 이미 가입한 사용자의 서버 데이터를 보정하는 V2 API
public enum MigrationAPI {
    /// `PATCH /api/v2/user/signup-os`. 서버가 V2 마이그레이션 명세(`cc55e51`) 뒤에 추가했다(2026-10-25).
    ///
    /// 가입 OS가 비어 있으면 저장하고, 이미 값이 있으면 유지한다. 성공 응답은 빈 본문이다.
    ///
    /// 시작할 때 꺼낸 Access Token을 헤더에 직접 담고 인증 plugin을 거치지 않는다. 토큰 갱신 뒤 다시 보내면
    /// 그사이 로그인한 다른 계정의 토큰이 실릴 수 있어서다. 토큰이 만료돼 실패하면 다음 실행 때 다시 한다.
    case fillSignupOs(accessToken: String)
}

extension MigrationAPI: BaseAPI {
    public var apiVersion: APIVersion {
        .v2
    }

    public var authorization: APIAuthorization {
        .none
    }

    public var path: String {
        switch self {
        case .fillSignupOs:
            return "/user/signup-os"
        }
    }

    public var headers: [String: String]? {
        switch self {
        case .fillSignupOs(let accessToken):
            return [
                "Content-Type": "application/json",
                "accept": "application/json",
                "Authorization": "Bearer \(accessToken)",
            ]
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
