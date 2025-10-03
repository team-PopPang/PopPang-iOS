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
        plugins: [NetworkLoggerPlugin(configuration: .init(logOptions: .verbose))]
    )
    
    let kakaoProvider = MoyaProvider<KakaoAuthAPI>(
        plugins: [NetworkLoggerPlugin(configuration: .init(logOptions: .verbose))]
    )
    
    let userProvider = MoyaProvider<UserAPI>(
        plugins: [NetworkLoggerPlugin(configuration: .init(logOptions: .verbose))]
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
