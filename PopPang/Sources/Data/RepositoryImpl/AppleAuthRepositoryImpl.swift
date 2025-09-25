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
        let userDto = try await sendAuthCodeToServer(authCode: authCode)
        return userDto.toModel()
    }
}

// MARK: - PopPang 서버 요청
extension AppleAuthRepositoryImpl {
    
    // 서버에 accessToken 보낸 후 서버에서 idToken 받고 uid 식별 후 유저 반환
    private func sendAuthCodeToServer(authCode: String) async throws -> UserDTO {
        guard let url = URL(string: Constants.PopPangAPI.url) else {
            throw AppleAuthError.invalidAuthCode
        }
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        let bodyString = "code=\(authCode)"
        request.httpBody = bodyString.data(using: .utf8)

        let (data, response) = try await URLSession.shared.data(for: request)
        guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
            throw AppleAuthError.serverError("Invalid response")
        }
        print("data: \(data)")
        print("response data:", String(data: data, encoding: .utf8) ?? "invalid encoding")
        return try JSONDecoder().decode(UserDTO.self, from: data)
    }
}
