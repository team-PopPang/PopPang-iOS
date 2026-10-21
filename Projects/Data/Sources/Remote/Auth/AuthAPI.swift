import Core
import Domain
import Foundation
import Moya

/// V2 인증 API
public enum AuthAPI {
    case login(SocialCredential)
    case signup(provider: Provider, request: V2SignupRequestDTO)
    /// 가입 화면의 닉네임 중복 확인
    case signupNicknameDuplicated(nickname: String)
    /// 가입 화면의 관심 카테고리 목록
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
