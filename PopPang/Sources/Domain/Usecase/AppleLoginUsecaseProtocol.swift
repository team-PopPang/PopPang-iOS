//
//  AuthUsecaseProtocol.swift
//  PopPang
//
//  Created by 김동현 on 9/22/25.
//

import Foundation
import AuthenticationServices

protocol AppleLoginUsecaseProtocol {
    /// Apple 로그인 -> auth code 반환
    func appleLogin(authorization: ASAuthorization) async throws -> String
}

final class AppleLoginUsecaseImpl: AppleLoginUsecaseProtocol {
    
    private func sendAuthCodeToServer(_ code: String) async throws -> String {
        // 서버 통신 로직
        return "server_generated_uid"
    }
    
    func appleLogin(authorization: ASAuthorization) async throws -> String {
        guard let credential = authorization.credential as? ASAuthorizationAppleIDCredential,
              let authCodeData = credential.authorizationCode,
              let authcode = String(data: authCodeData, encoding: .utf8) else {
            throw URLError(.badServerResponse)
        }
        
        let uid = try await sendAuthCodeToServer(authcode)
        return uid
    }
}
