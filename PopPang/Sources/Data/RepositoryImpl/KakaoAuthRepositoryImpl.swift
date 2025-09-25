//
//  KakaoAuthRepositoryImpl.swift
//  PopPang
//
//  Created by 김동현 on 9/25/25.
//

import KakaoSDKAuth
import KakaoSDKUser

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
        let user = try await requestUserToServer(accessToken: oauthToken.accessToken)
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
    private func requestUserToServer(accessToken: String) async throws -> User {
//        guard let url = URL(string: "https://index.zapto.org/api/oauth2/kakaoLogin") else {
//            throw KakaoAuthError.invalidURL
//        }
//
//        var request = URLRequest(url: url)
//        request.httpMethod = "POST"
//        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
//
//        let body: [String: Any] = ["accessToken": accessToken]
//        request.httpBody = try JSONSerialization.data(withJSONObject: body)
//
//        let (data, response) = try await URLSession.shared.data(for: request)
//
//        guard let httpResponse = response as? HTTPURLResponse,
//              httpResponse.statusCode == 200 else {
//            throw KakaoAuthError.serverError
//        }
//
//        do {
//            return try JSONDecoder().decode(User.self, from: data)
//        } catch {
//            throw KakaoAuthError.decodeError
//        }
        return User.adminUser
    }
}
