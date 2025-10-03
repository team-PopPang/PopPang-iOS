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
        
        let userDTO = try await NetworkProvider.shared.kakaoProvider.asyncRequest(.login(accessToken: oauthToken.accessToken), decodeTo: UserDTO.self)
         return userDTO.toModel()
        
         // return User.adminUser
    }
    
    func kakaoRegister(user: User) async throws -> User {
        let userDTO = try await NetworkProvider.shared.kakaoProvider.asyncRequest(.signup(userDTO: user.toDTO()),
                                                                                  decodeTo: UserDTO.self)
        return userDTO.toModel()
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
                    continuation.resume(throwing: KakaoAuthRepositoryError.tokenNotFound)
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
                    continuation.resume(throwing: KakaoAuthRepositoryError.tokenNotFound)
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
