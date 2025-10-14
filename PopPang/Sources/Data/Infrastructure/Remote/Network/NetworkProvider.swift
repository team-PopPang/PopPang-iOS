//
//  NetworkProvider.swift
//  PopPang
//
//  Created by 김동현 on 10/3/25.
//

import Moya
import Foundation

final class NetworkProvider {
    static let shared = NetworkProvider()
    private init() {}
    
    let appleProvider = MoyaProvider<AppleAuthAPI>(
        // plugins: [NetworkLoggerPlugin(configuration: .init(logOptions: .verbose))]
    )
    
    let kakaoProvider = MoyaProvider<KakaoAuthAPI>(
        // plugins: [NetworkLoggerPlugin(configuration: .init(logOptions: .verbose))]
    )
    
    let googleProvider = MoyaProvider<GoogleAuthAPI>(
        // plugins: [NetworkLoggerPlugin(configuration: .init(logOptions: .verbose))]
    )
    
    let userProvider = MoyaProvider<UserAPI>(
        // plugins: [NetworkLoggerPlugin(configuration: .init(logOptions: .verbose))]
    )
    
    let popupProvidder = MoyaProvider<PopupAPI>(
        // plugins: [NetworkLoggerPlugin(configuration: .init(logOptions: .verbose))]
    )
}

extension MoyaProvider {
    /// async/await 지원 네트워크 요청
    func asyncRequest<T: Decodable>(_ target: Target,
                                    decodeTo type: T.Type) async throws -> T {
        try await withCheckedThrowingContinuation { continuation in
            self.request(target) { result in
                switch result {
                case .success(let response):
                    do {
                        
                        // 서버 응답코드가 200~299 범위 인지
                        guard (200..<300).contains(response.statusCode) else {
                            let msg = String(data: response.data, encoding: .utf8) ?? "Unknown error"
                            continuation.resume(throwing: NSError(
                                domain: "NetworkError",
                                code: response.statusCode,
                                userInfo: [NSLocalizedDescriptionKey: msg]
                            ))
                            return
                        }
                        
                        let decoded = try JSONDecoder().decode(T.self, from: response.data)
                        continuation.resume(returning: decoded)
                    } catch {
                        continuation.resume(throwing: error)
                    }
                case .failure(let error):
                    continuation.resume(throwing: error)
                }
            }
        }
    }
}

// MARK: - 상태코드 알고싶을 떄
extension MoyaProvider {
    /// Decoding이 필요 없는 요청 (예: 200 OK만 반환되는 API)
    func asyncRequest(_ target: Target) async throws -> Response {
        try await withCheckedThrowingContinuation { continuation in
            self.request(target) { result in
                switch result {
                case .success(let response):
                    guard (200..<300).contains(response.statusCode) else {
                        let msg = String(data: response.data, encoding: .utf8) ?? "Unknown error"
                        continuation.resume(throwing: NSError(
                            domain: "NetworkError",
                            code: response.statusCode,
                            userInfo: [NSLocalizedDescriptionKey: msg]
                        ))
                        return
                    }
                    continuation.resume(returning: response)
                    
                case .failure(let error):
                    continuation.resume(throwing: error)
                }
            }
        }
    }
}

// MARK: - 상태코드도 필요없을 때
extension MoyaProvider {
    func asyncRequestVoid(_ target: Target) async throws {
        let response = try await asyncRequest(target)
        guard (200..<300).contains(response.statusCode) else {
            throw NSError(domain: "NetworkError", code: response.statusCode)
        }
    }
}
