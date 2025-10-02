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
        let user = try await requestUserToServer(accessToken: oauthToken.accessToken).toModel()
        return user
    }
    
    func kakaoLogout() async throws {
        try await handleKakaoLogout()
    }
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

// MARK: - PopPang 서버 요청
extension KakaoAuthRepositoryImpl {
    // 서버에 accessToken 보낸 후 서버에서 idToken 받고 uid 식별 후 유저 반환
    private func requestUserToServer(accessToken: String) async throws -> UserDTO {
        print("✅ requestUserToServer 실행됨, code: \(accessToken)")
        
        // ✅ URL + queryItems 로 code 전달
        guard var components = URLComponents(string: Constants.PopPangAPI.kakaoURL) else {
            throw AppleAuthError.invalidAuthCode
        }
        components.queryItems = [
            URLQueryItem(name: "code", value: accessToken)
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

