//
//  SceneDelegate.swift
//  PopPang
//
//  Created by 김동현 on 9/24/25.
//

import UIKit
import KakaoSDKAuth

class SceneDelegate: UIResponder, UIWindowSceneDelegate {

    
    /// 앱이 외부 URL을 열려고 할 때 호출
    ///
    /// - Parameters:
    ///   - scene: 현재 활성화된 씬 객체. (멀티 윈도우 환경에서 어떤 씬이 URL을 받았는지 구분)
    ///   - URLContexts: 앱을 실행시킨 외부 URL과 관련된 컨텍스트 집합
    ///
    /// - Note: 카카오톡 로그인 완료 후 카카오톡 앱에서 전달한 URL을 처리하는 데 사용
    ///   내부적으로 `AuthController.handleOpenUrl`에 위임하여 인증 토큰을 교환
    func scene(_ scene: UIScene, openURLContexts URLContexts: Set<UIOpenURLContext>) {
        if let url = URLContexts.first?.url {
            if (AuthApi.isKakaoTalkLoginUrl(url)) {
                _ = AuthController.handleOpenUrl(url: url)
            }
        }
    }
}
