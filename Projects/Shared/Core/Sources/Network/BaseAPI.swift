import Foundation
import Moya

/// 서버 API 버전. V1과 V2는 경로 모양이 달라서 버전마다 기본 URL을 나눈다.
public enum APIVersion: String, Sendable {
    case v1
    case v2
}

/// 요청에 붙일 `Authorization` 헤더 종류.
public enum APIAuthorization: Sendable {
    /// 헤더를 보내지 않는다. V1 API와 V2 공개 API(소셜 로그인, 토큰 갱신)가 해당한다.
    case none
    /// `Bearer {accessToken}`을 보낸다.
    case access
    /// `Bearer {signupToken}`을 보낸다. V2 회원가입 API에만 쓴다.
    case signup
}

public protocol BaseAPI: TargetType {
    var apiVersion: APIVersion { get }
    var authorization: APIAuthorization { get }
}

public extension BaseAPI {
    var apiVersion: APIVersion {
        .v1
    }

    var authorization: APIAuthorization {
        .none
    }

    var baseURL: URL {
        NetworkConfig.apiBaseURL(for: apiVersion)
    }

    var headers: [String: String]? {
        [
            "Content-Type": "application/json",
            "accept": "application/json",
        ]
    }

    /// 실제로 적용할 인증 종류. V1 요청에는 서버 계약상 `Authorization` 헤더를 보내지 않는다.
    var resolvedAuthorization: APIAuthorization {
        apiVersion == .v1 ? .none : authorization
    }
}
