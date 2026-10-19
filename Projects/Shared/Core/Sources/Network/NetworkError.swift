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

    /// 실패 본문의 서버 에러 코드. 본문이 `ErrorResponse` 형식이 아니면(5xx 기본 오류 본문 등) `nil`이다.
    public var serverErrorCode: Int? {
        switch self {
        case let .invalidStatusCode(_, message):
            return try? JSONDecoder()
                .decode(ErrorResponse.self, from: Data(message.utf8))
                .code
        }
    }
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
