import Foundation
import Moya

public extension MoyaProvider {
    func asyncRequest<T: Decodable>(
        _ target: Target,
        decodeTo type: T.Type,
        decoder: JSONDecoder = JSONDecoder()
    ) async throws -> T {
        let response = try await asyncRequest(target)
        return try decoder.decode(T.self, from: response.data)
    }

    func asyncRequest(_ target: Target) async throws -> Response {
        try await withCheckedThrowingContinuation { continuation in
            request(target) { result in
                switch result {
                case let .success(response):
                    guard (200..<300).contains(response.statusCode) else {
                        let message = String(data: response.data, encoding: .utf8) ?? "Unknown error"
                        continuation.resume(
                            throwing: NetworkError.invalidStatusCode(
                                response.statusCode,
                                message: message
                            )
                        )
                        return
                    }

                    continuation.resume(returning: response)

                case let .failure(error):
                    continuation.resume(throwing: error)
                }
            }
        }
    }

    func asyncRequestVoid(_ target: Target) async throws {
        _ = try await asyncRequest(target)
    }
}
