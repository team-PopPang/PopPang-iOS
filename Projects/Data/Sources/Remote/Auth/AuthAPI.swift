import Core
import Domain
import Foundation
import Moya

/// V2 인증 API
public enum AuthAPI {
    case login(SocialCredential)
    case signup(provider: Provider, request: V2SignupRequestDTO)
    /// 가입 화면의 닉네임 중복 확인 (`GET /api/v2/user/nickname/duplicated`, 명세 USER-04)
    ///
    /// 명세는 Access Token 전용이지만, 서버가 Signup Token으로도 부를 수 있게 권한을 바꿔 운영에 배포했다(2026-10-21).
    /// 성공 응답은 `APIResponse`로 감싼 `{ isDuplicated }`다.
    case signupNicknameDuplicated(nickname: String)
    /// 가입 화면의 관심 카테고리 목록 (`GET /api/v2/recommend`, 명세 RECO-01)
    ///
    /// 권한은 위와 같이 Signup Token을 허용한다. 성공 응답은 명세상 V1과 같은 감싸지 않은 배열(`wrapper NONE → NONE`)이라
    /// `asyncRequest(_:decodeTo:)`로 읽는다.
    case signupRecommendList
    /// 로그아웃. 기기의 토큰을 먼저 지운 뒤 보내므로 저장소 대신 꺼내 둔 Access Token을 직접 담는다.
    case logout(accessToken: String)
    case me
}

extension AuthAPI: BaseAPI {
    public var apiVersion: APIVersion {
        .v2
    }

    public var authorization: APIAuthorization {
        switch self {
        case .login, .logout:
            return .none
        case .signup, .signupNicknameDuplicated, .signupRecommendList:
            return .signup
        case .me:
            return .access
        }
    }

    public var path: String {
        switch self {
        case .login(let credential):
            return "/auth/\(credential.provider.pathComponent)/mobile/login"
        case .signup(let provider, _):
            return "/auth/\(provider.pathComponent)/signup"
        case .signupNicknameDuplicated:
            return "/user/nickname/duplicated"
        case .signupRecommendList:
            return "/recommend"
        case .logout:
            return "/auth/logout"
        case .me:
            return "/user"
        }
    }

    public var method: Moya.Method {
        switch self {
        case .me, .signupNicknameDuplicated, .signupRecommendList:
            return .get
        case .login, .signup, .logout:
            return .post
        }
    }

    public var headers: [String: String]? {
        var headers = [
            "Content-Type": "application/json",
            "accept": "application/json",
        ]
        if case let .logout(accessToken) = self {
            headers["Authorization"] = "Bearer \(accessToken)"
        }
        return headers
    }

    public var task: Task {
        switch self {
        case .login(.kakao(let accessToken)):
            return .requestJSONEncodable(["access_token": accessToken])
        case .login(.google(let idToken)):
            return .requestJSONEncodable(["id_token": idToken])
        case .login(.apple(let authCode, let rawNonce)):
            return .requestJSONEncodable([
                "auth_code": authCode,
                "raw_nonce": rawNonce,
            ])
        case .signup(_, let request):
            return .requestJSONEncodable(request)
        case .signupNicknameDuplicated(let nickname):
            return .requestParameters(parameters: ["nickname": nickname], encoding: URLEncoding.queryString)
        case .logout, .me, .signupRecommendList:
            return .requestPlain
        }
    }
}

extension Provider {
    var pathComponent: String {
        rawValue.lowercased()
    }
}
