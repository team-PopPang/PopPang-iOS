import Core
import Domain
import Foundation
import Moya

/// V2 인증 API
public enum AuthAPI {
    case login(SocialCredential)
    case signup(provider: Provider, request: V2SignupRequestDTO)
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
        case .signup:
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
        case .logout:
            return "/auth/logout"
        case .me:
            return "/user"
        }
    }

    public var method: Moya.Method {
        switch self {
        case .me:
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
        case .logout, .me:
            return .requestPlain
        }
    }
}

extension Provider {
    var pathComponent: String {
        rawValue.lowercased()
    }
}
