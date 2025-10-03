//
//  KakaoAuthRepositoryImpl.swift
//  PopPang
//
//  Created by 김동현 on 9/25/25.
//

import KakaoSDKAuth
import KakaoSDKUser
import UIKit

final class KakaoAuthRepositoryImpl: KakaoAuthRepositoryProtocol {
    
    func kakaoLogin() async throws -> User {
        let oauthToken: OAuthToken

        // 1. 카카오톡앱 설치 여부 확인
        if (UserApi.isKakaoTalkLoginAvailable()) {
            // 앱으로 로그인
            oauthToken = try await handleWithKakaoApp()
        }
        else {
            // 웹뷰로 로그인
            oauthToken = try await handleWithKakaoWeb()
        }
        
        // 2. PopPang 서버에 토큰 전달 및 유저 반환
        // let user = try await requestUserToServer(accessToken: oauthToken.accessToken).toModel()
        // return user
        
//        let userDto = try await NetworkProvider.shared.kakaoProvider.asyncRequest(.login(accessToken: oauthToken.accessToken), decodeTo: UserDTO.self)
//         print(userDto)
//         return userDto.toModel()
        
         return User.adminUser
    }
    
    /*
    func kakaoLogout() async throws {
        try await handleKakaoLogout()
    }
     */
}

// MARK: - kakao 서버 요청
extension KakaoAuthRepositoryImpl {
    // 카카오 앱으로 로그인
    @MainActor
    private func handleWithKakaoApp() async throws -> OAuthToken {
        try await withCheckedThrowingContinuation { continuation in
            // 앱으로 로그인
            UserApi.shared.loginWithKakaoTalk {(oauthToken, error) in
                if let error = error {
                    continuation.resume(throwing: error)
                }
                else if let token = oauthToken {
                    continuation.resume(returning: token)
                }
                else {
                    continuation.resume(throwing: KakaoAuthError.tokenNotFound)
                }
            }
        }
    }
    
    // 카카오 웹뷰로 로그인
    @MainActor
    private func handleWithKakaoWeb() async throws -> OAuthToken {
        try await withCheckedThrowingContinuation { continuation in
            // 웹뷰로 로그인
            UserApi.shared.loginWithKakaoAccount {(oauthToken, error) in
                if let error = error {
                    continuation.resume(throwing: error)
                }
                else if let token = oauthToken {
                    continuation.resume(returning: token)
                }
                else {
                    continuation.resume(throwing: KakaoAuthError.tokenNotFound)
                }
            }
        }
    }
    
    // 카카오 로그아웃
    @MainActor
    private func handleKakaoLogout() async throws {
        return try await withCheckedThrowingContinuation { continuation in
            UserApi.shared.logout { error in
                if let error = error {
                    continuation.resume(throwing: error)
                }
                else {
                    print("logout() success.")
                    continuation.resume(returning: ())
                }
            }
        }
    }
}


/*
// MARK: - PopPang 서버 요청
extension KakaoAuthRepositoryImpl {
    private func requestUserToServerURLSession(accessToken: String) async throws -> UserDTO {
        print("✅ requestUserToServer 실행됨, accessToken: \(accessToken)")

        guard let url = URL(string: Constants.PopPangAPI.apiURL) else {
            throw AppleAuthError.invalidAuthCode
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        // ✅ 서버 DTO와 동일한 JSON Body
        let body = ["access_token": accessToken]
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
