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
            throw AppleAuthRepositoryError.authCodeNotFound
        }
    
        let userDTO = try await NetworkProvider.shared.appleProvider.asyncRequest(.login(authCode: authCode),
                                                                                  decodeTo: UserDTO.self)
        return userDTO.toModel()
    }
    
    func appleRegister(user: User) async throws -> User {
        let userDto =  try await NetworkProvider.shared.appleProvider.asyncRequest(.signup(userDto: user.toDTO()), decodeTo: UserDTO.self)
        return userDto.toModel()
    }
}















// 서버에 authCode 전달
// let userDto = try await requestUserToServer(authCode: authCode)
// return userDto.toModel()

/*
// MARK: - Moya Completion 방식
extension AppleAuthRepositoryImpl {
    // 서버에 authCode 보낸 후 서버에서 idToken 받고 uid 식별 후 유저 반환
    private func requestUserToServerMoya(authCode: String) async throws -> UserDTO {
        return try await withCheckedThrowingContinuation { continuation in
            NetworkProvider.shared.appleProvider.request(.login(authCode: authCode)) { result in
                switch result {
                case .success(let response):
                    do {
                        let dto = try JSONDecoder().decode(UserDTO.self, from: response.data)
                        continuation.resume(returning: dto)
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

// MARK: - URLSession 방식
extension AppleAuthRepositoryImpl {
    // 서버에 authCode 보낸 후 서버에서 idToken 받고 uid 식별 후 유저 반환
    private func requestUserToServerUrlSession(authCode: String) async throws -> UserDTO {
        print("✅ requestUserToServer 실행됨, authCode: \(authCode)")

        guard let url = URL(string: Constants.PopPangAPI.apiURL) else {
            throw AppleAuthError.invalidAuthCode
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        // ✅ 서버 DTO와 동일한 JSON Body
        let body = ["auth_code": authCode]
        request.httpBody = try JSONSerialization.data(withJSONObject: body, options: [])

        print("➡️ Request URL: \(url.absoluteString)")
        print("➡️ Request Method: \(request.httpMethod ?? "")")
        if let jsonString = String(data: request.httpBody ?? Data(), encoding: .utf8) {
            print("➡️ Request Body JSON: \(jsonString)")
        }

        let (data, response) = try await URLSession.shared.data(for: request)

        if let httpResponse = response as? HTTPURLResponse {
            print("📡 Status Code: \(httpResponse.statusCode)")
            guard httpResponse.statusCode == 200 else {
                throw AppleAuthError.serverError("Invalid response: \(httpResponse.statusCode)")
            }
        }

        print("📦 Raw Data size: \(data.count) bytes")
        if let jsonString = String(data: data, encoding: .utf8) {
            print("📦 Response Body String:\n\(jsonString)")
        }

        return try JSONDecoder().decode(UserDTO.self, from: data)

    }
}
*/
