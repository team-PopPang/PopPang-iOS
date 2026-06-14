import Foundation

public enum NetworkError: LocalizedError, Equatable, Sendable {
    case invalidStatusCode(Int, message: String)

    public var errorDescription: String? {
        switch self {
        case let .invalidStatusCode(code, message):
            return "Request failed with status code \(code): \(message)"
        }
    }
}
