//
//  KakaoAuthUsecaseProtocol.swift
//  PopPang
//
//  Created by 김동현 on 9/25/25.
//

import Foundation

protocol KakaoAuthUsecaseProtocol {
    func kakaoLogin() async throws -> User
    func kakaoLogout() async throws
}
