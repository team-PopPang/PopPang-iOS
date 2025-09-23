//
//  AppleLoginUsecase.swift
//  PopPang
//
//  Created by 김동현 on 9/23/25.
//

import Foundation
import AuthenticationServices

final class AppleLoginUsecaseImpl: AppleLoginUsecaseProtocol {
    
    func appleLogin(authorization: ASAuthorization) async throws -> User {
        guard let credential = authorization.credential as? ASAuthorizationAppleIDCredential,
              let authCodeData = credential.authorizationCode,
              let authCode = String(data: authCodeData, encoding: .utf8) else {
            throw AuthError.invalidAuthCode
        }
        print("auth code: \(authCode)")
        
        // 서버에 authCode 전달
        let userDto = try await sendAuthCodeToServer(authCode: authCode)
        return userDto.toModel()
    }
    
    private func sendAuthCodeToServer(authCode: String) async throws -> UserDTO {

        guard let url = URL(string: "https://index.zapto.org/api/oauth2/appleLogin") else {
            throw AuthError.invalidAuthCode
        }
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        let bodyString = "authCode=\(authCode)"
        request.httpBody = bodyString.data(using: .utf8)
        
        let (data, response) = try await URLSession.shared.data(for: request)
        guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
            throw AuthError.serverError("Invalid response")
        }
        print("data: \(data)")
        return try JSONDecoder().decode(UserDTO.self, from: data)
    }
}

final class StubAppleLoginUsecaseImpl: AppleLoginUsecaseProtocol {
    
    func appleLogin(authorization: ASAuthorization) async throws -> User {
        guard let credential = authorization.credential as? ASAuthorizationAppleIDCredential,
              let authCodeData = credential.authorizationCode,
              let authCode = String(data: authCodeData, encoding: .utf8) else {
            throw AuthError.invalidAuthCode
        }
        
        // 서버에 authCode 전달
        let userDto = try await sendAuthCodeToServer(authCode: authCode)
        return userDto.toModel()
    }
    
    private func sendAuthCodeToServer(authCode: String) async throws -> UserDTO {
        /*
        var request = URLRequest(url: URL(string: "https://api.poppang.com/auth/apple")!)
        request.httpMethod = "POST"
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try JSONSerialization.data(withJSONObject: ["authCode": code])
        
        let (data, response) = try await URLSession.shared.data(for: request)
        guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
            throw AuthError.serverError("Invalid response")
        }
         return try JSONDecoder().decode(UserDTO.self, from: data)
         */
        print("authCode: \(authCode)")
        return UserDTO(
            uid: "stub-uid-123",
            email: "stub@example.com",
            nickname: "김동현",
            //nickname: nil, // 닉네임 없음 → 신규가입 플로우로 유도
            role: "member",
            provider: "apple",
            keywords: [],
            recommands: []
        )
    }
}
