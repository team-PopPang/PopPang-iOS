//
//  SceneDelegate.swift
//  PopPang
//
//  Created by 김동현 on 9/24/25.
//
//
//import UIKit
//import KakaoSDKAuth
//
//class SceneDelegate: UIResponder, UIWindowSceneDelegate {
//
//    
//    /// 앱이 외부 URL을 열려고 할 때 호출
//    ///
//    /// - Parameters:
//    ///   - scene: 현재 활성화된 씬 객체. (멀티 윈도우 환경에서 어떤 씬이 URL을 받았는지 구분)
//    ///   - URLContexts: 앱을 실행시킨 외부 URL과 관련된 컨텍스트 집합
//    ///
//    /// - Note: 카카오톡 로그인 완료 후 카카오톡 앱에서 전달한 URL을 처리하는 데 사용
//    ///   내부적으로 `AuthController.handleOpenUrl`에 위임하여 인증 토큰을 교환
//    func scene(_ scene: UIScene, openURLContexts URLContexts: Set<UIOpenURLContext>) {
//        if let url = URLContexts.first?.url {
//            if (AuthApi.isKakaoTalkLoginUrl(url)) {
//                _ = AuthController.handleOpenUrl(url: url)
//            }
//        }
//    }
//    
//
//    /// ✅ 2. 유니버설 링크 (https://poppang.co.kr/popup/1234) 처리
//    ///
//    /// Safari, 카카오톡, 메시지 등에서 유니버설 링크를 클릭했을 때 호출됨
//    func scene(_ scene: UIScene, continue userActivity: NSUserActivity) {
//        print("✅ [SceneDelegate] continue userActivity 호출됨")
//
//        guard userActivity.activityType == NSUserActivityTypeBrowsingWeb,
//              let incomingURL = userActivity.webpageURL else {
//            print("⚠️ [SceneDelegate] userActivity.webpageURL 없음")
//            return
//        }
//
//        print("🌐 [SceneDelegate] URL: \(incomingURL.absoluteString)")
//        
//        handleUniversalLink(incomingURL)
//    }
//
//
//    /// ✅ 3. 유니버설 링크 분석 및 popupId 전달
//    ///
//    /// - Parameter url: https://poppang.co.kr/popup/{popupId}
//    /// - Note: popupId를 파싱 후 `.didReceiveDeepLink` 알림으로 앱 전역에 전달
//    private func handleUniversalLink(_ url: URL) {
//        let pathComponents = url.pathComponents
//        guard pathComponents.count >= 2 else { return }
//
//        // 예: /popup/2a9e97... → "popup", "2a9e97..."
//        if pathComponents.contains("popup"),
//           let popupId = pathComponents.last {
//            Logger.d("유니버설 링크 popupId 파싱: \(popupId)")
//            NotificationCenter.default.post(
//                name: .didReceiveDeepLink,
//                object: nil,
//                userInfo: ["popupId": popupId]
//            )
//            Logger.d("유니버설 링크 popupId를 앱 전체에 브로드캐스트")
//        }
//    }
//}



import UIKit
import KakaoSDKAuth

class SceneDelegate: UIResponder, UIWindowSceneDelegate {

    func scene(_ scene: UIScene, openURLContexts URLContexts: Set<UIOpenURLContext>) {
        guard let url = URLContexts.first?.url else { return }

        // ✅ 카카오 로그인 처리
        if AuthApi.isKakaoTalkLoginUrl(url) {
            _ = AuthController.handleOpenUrl(url: url)
            return
        }

        // ✅ 카카오 공유로 들어온 링크 (kakao57dbc...://kakaolink?popupId=xxx)
        if url.scheme?.hasPrefix("kakao") == true, url.host == "kakaolink" {
            if let components = URLComponents(url: url, resolvingAgainstBaseURL: false),
               let popupId = components.queryItems?.first(where: { $0.name == "popupId" })?.value {
                Logger.d("📩 카카오 스킴으로 들어옴 — popupId: \(popupId)")

                NotificationCenter.default.post(
                    name: .didReceiveDeepLink,
                    object: nil,
                    userInfo: ["popupId": popupId]
                )
            }
            return
        }

        // ✅ 유니버설 링크 (https://poppang.co.kr/popup/xxx)
        if url.absoluteString.hasPrefix("https://poppang.co.kr/popup/") {
            let popupId = url.lastPathComponent
            Logger.d("🌐 유니버설 링크로 들어옴 — popupId: \(popupId)")

            NotificationCenter.default.post(
                name: .didReceiveDeepLink,
                object: nil,
                userInfo: ["popupId": popupId]
            )
        }
    }
}
