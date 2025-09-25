//
//  KakaoAuthUsecaseImpl.swift
//  PopPang
//
//  Created by 김동현 on 9/25/25.
//

import Foundation

protocol KakaoAuthUsecaseProtocol {
    func kakaoLogin() async throws -> User
    func kakaoLogout() async throws
}

final class KakaoAuthUsecaseImpl: KakaoAuthUsecaseProtocol {
    private let kakaoAuthRepository: KakaoAuthRepositoryProtocol
    
    init(kakaoAuthRepository: KakaoAuthRepositoryProtocol) {
        self.kakaoAuthRepository = kakaoAuthRepository
    }
    
    func kakaoLogin() async throws -> User {
        try await kakaoAuthRepository.kakaoLogin()
    }
    
    func kakaoLogout() async throws {
        try await kakaoAuthRepository.kakaoLogout()
    }
}
