import Foundation

public enum NetworkError: LocalizedError, Equatable, Sendable {
    case invalidStatusCode(Int, message: String)

    public var errorDescription: String? {
        switch self {
        case let .invalidStatusCode(code, message):
            return "Request failed with status code \(code): \(message)"
        }
    }

    public var statusCode: Int {
        switch self {
        case let .invalidStatusCode(code, _):
            return code
        }
    }

    /// 실패 본문의 서버 에러 코드. 본문에 정수 `code`가 없으면(5xx 기본 오류 본문 등) `nil`이다.
    ///
    /// `ErrorResponse`의 다른 필드가 빠져도 코드는 읽도록 `code`만 디코딩한다.
    public var serverErrorCode: Int? {
        switch self {
        case let .invalidStatusCode(_, message):
            return try? JSONDecoder()
                .decode(ServerErrorCodeBody.self, from: Data(message.utf8))
                .code
        }
    }
}

private struct ServerErrorCodeBody: Decodable {
    let code: Int
}

public extension NetworkError {
    /// V2 서버 에러 코드 가운데 앱이 따로 처리하는 값.
    enum ServerErrorCode {
        public static let expiredToken = 5002
    }

    /// Access Token이 만료된 응답(401 5002)인지 확인한다.
    var isExpiredToken: Bool {
        statusCode == 401 && serverErrorCode == ServerErrorCode.expiredToken
    }
}
