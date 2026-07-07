//
//  SceneDelegate.swift
//  PopPang
//
//  Created by 김동현 on 9/24/25.
//
//

import UIKit
import KakaoSDKAuth

class SceneDelegate: UIResponder, UIWindowSceneDelegate {
    
    
    // MARK: - 앱이 완전히 꺼져 있을 때(Cold Start) 호출됨
    func scene(_ scene: UIScene,
               willConnectTo session: UISceneSession,
               options connectionOptions: UIScene.ConnectionOptions) {
        
        if let urlContext = connectionOptions.urlContexts.first {
            handleIncomingURL(urlContext.url)
        }
    }
    
    
    // MARK: - 앱이 이미 켜져 있을 때((Background → Foreground) 호출됨)
    /// 앱이 외부 URL(딥링크, 로그인 콜백 등)을 통해 실행될 때 호출하는 메서드
    /// 카카오 로그인 완료, 카카오 공유 링크 클릭, 유니버셜 링크 클릭 등
    /// 주요 역할:
    /// 1. **카카오 로그인 콜백 처리**
    ///    - 카카오톡 앱을 통한 로그인 인증이 완료된 후 돌아올 때 호출됩니다.
    ///    - `AuthController.handleOpenUrl(url:)`을 통해 인증 토큰 교환을 수행합니다.
    ///
    /// 2. **카카오 공유 스킴 처리**
    ///    - 카카오톡에서 공유된 `kakao{앱키}://kakaolink?popupId=xxx` 형태의 링크를 클릭했을 때 호출됩니다.
    ///    - URL 쿼리에서 `popupId`를 추출하여 NotificationCenter를 통해 앱 내부로 전달합니다.
    ///    - 예시 URL: `kakao57dbc12345://kakaolink?popupId=abcd-1234`
    ///
    /// 3. **유니버설 링크 처리**
    ///    - 웹 브라우저, 메신저 등에서 `https://poppang.co.kr/popup/xxx` 형태의 링크를 클릭했을 때 호출됩니다.
    ///    - URL의 마지막 path를 popupId로 인식하고 NotificationCenter로 전달합니다.
    ///    - 예시 URL: `https://poppang.co.kr/popup/abcd-1234`
    /// - Parameters:
    ///   - scene: 현재 활성화된 씬 객체 (멀티 윈도우 환경에서 어떤 씬이 URL을 받았는지 구분)
    ///   - URLContexts: 앱을 실행시킨 외부 URL과 관련된 컨텍스트 집합
    func scene(_ scene: UIScene, openURLContexts URLContexts: Set<UIOpenURLContext>) {
        guard let url = URLContexts.first?.url else { return }
        handleIncomingURL(url)
    }
    
    // ✅ 공통 URL 처리 로직
    private func handleIncomingURL(_ url: URL) {
        // 카카오 로그인 처리
        if AuthApi.isKakaoTalkLoginUrl(url) {
            _ = AuthController.handleOpenUrl(url: url)
            return
        }
        
        // ✅ 카카오 공유로 들어온 링크 (kakao57dbc...://kakaolink?popupId=xxx)
        if url.scheme?.hasPrefix("kakao") == true, url.host == "kakaolink" {
            if let components = URLComponents(url: url, resolvingAgainstBaseURL: false),
               let popupId = components.queryItems?.first(where: { $0.name == "popupId" })?.value {
                Logger.d("카카오 스킴으로 들어옴 — popupId: \(popupId)")
                UserDefaultsManager.saveDeeplinkPopupId(popupId)
            }
            return
        }
        
        // 유니버설 링크 처리 (웹 주소로 연결된 경우)(https://poppang.co.kr/popup/xxx)
        if url.absoluteString.hasPrefix("https://poppang.co.kr/popup/") {
            let popupId = url.lastPathComponent
            Logger.d("유니버설 링크로 들어옴 — popupId: \(popupId)")
            UserDefaultsManager.saveDeeplinkPopupId(popupId)
        }
    }
}
