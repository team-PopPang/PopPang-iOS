//
//  KakaoAuthRepositoryProtocol.swift
//  PopPang
//
//  Created by 김동현 on 9/25/25.
//

import KakaoSDKAuth
import KakaoSDKUser

enum KakaoAuthRepositoryError: Error {
    case tokenNotFound // 토큰 없음
}

protocol KakaoAuthRepositoryProtocol {
    
    /// 카카오 로그인
    /// - 앱 설치 유무에 따라 앱로그인 또는 웹뷰로 로그인을 진행합니다
    /// - Returns: User
    func kakaoLogin() async throws -> User
    
    /// 카카오 회원가입
    /// - Parameter user: 회원가입 정보
    /// - Returns: 유저 정보
    func kakaoRegister(user: User) async throws -> User
}
