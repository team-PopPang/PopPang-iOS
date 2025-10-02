//
//  AppleAuthRepositoryImpl.swift
//  PopPang
//
//  Created by 김동현 on 9/25/25.
//

import Foundation
import AuthenticationServices

final class AppleAuthRepositoryImpl: AppleAuthRepositoryProtocol {
    func appleLogin(authorization: ASAuthorization) async throws -> User {
        guard let credential = authorization.credential as? ASAuthorizationAppleIDCredential,
              let authCodeData = credential.authorizationCode,
              let authCode = String(data: authCodeData, encoding: .utf8) else {
            throw AppleAuthError.invalidAuthCode
        }
        
        // 서버에 authCode 전달
        let userDto = try await requestUserToServer(authCode: authCode)
        return userDto.toModel()
    }
}

// MARK: - PopPang 서버 요청
extension AppleAuthRepositoryImpl {
    // 서버에 authCode 보낸 후 서버에서 idToken 받고 uid 식별 후 유저 반환
    private func requestUserToServer(authCode: String) async throws -> UserDTO {
        print("✅ sendAuthCodeToServer 실행됨, code: \(authCode)")
        
        // ✅ URL + queryItems 로 code 전달
        guard var components = URLComponents(string: Constants.PopPangAPI.appleURL) else {
            throw AppleAuthError.invalidAuthCode
        }
        components.queryItems = [
            URLQueryItem(name: "code", value: authCode)
        ]
        
        guard let url = components.url else {
            throw AppleAuthError.invalidAuthCode
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "GET"  // ✅ GET은 body 없음
        
        print("➡️ Request URL: \(url.absoluteString)")
        print("➡️ Request Method: \(request.httpMethod ?? "")")
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        // 📦 data 출력
        print("📦 Raw Data size: \(data.count) bytes")
        if let jsonString = String(data: data, encoding: .utf8) {
            print("📦 Response Body String:\n\(jsonString)")
        } else {
            print("📦 Response Body: (디코딩 불가)")
        }
        
        // 📡 response 출력
        if let httpResponse = response as? HTTPURLResponse {
            print("📡 Status Code: \(httpResponse.statusCode)")
            print("📡 Headers:")
            for (key, value) in httpResponse.allHeaderFields {
                print("   \(key): \(value)")
            }
            
            guard httpResponse.statusCode == 200 else {
                throw AppleAuthError.serverError("Invalid response: \(httpResponse.statusCode)")
            }
        } else {
            throw AppleAuthError.serverError("Invalid response type")
        }
        
        return try JSONDecoder().decode(UserDTO.self, from: data)
    }
}
