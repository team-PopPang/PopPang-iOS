//
//  KakaoLoginViewModel.swift
//  PopPang
//
//  Created by 김동현 on 9/25/25.
//

import Foundation
import Combine
import KakaoSDKAuth
import KakaoSDKUser

final class KakaoAuthViewModel: ObservableObject {
    @Dependency private var kakaoAuthUsecase: KakaoAuthUsecaseProtocol
    

    func kakaoLogin() {
        Task {
            let user = try await kakaoAuthUsecase.kakaoLogin()
            print("유저: \(user)")
        }
    }

    func kakaoLogout() {
        Task {
            try await kakaoAuthUsecase.kakaoLogout()
        }
    }
}
