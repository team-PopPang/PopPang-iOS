import ADKit
import Core
import DSKit
import FirebaseCore
import KakaoSDKCommon
import NMapsMap
import UIKit

enum AppSDKInitializer {
    private static var isConfigured = false

    static func configure() {
        guard isConfigured == false else { return }
        isConfigured = true

        // UI 초기화
        UITabBar.configureAppearance()
        UINavigationBar.configureAppearance()
        
        // firebase 초기화
        FirebaseCoreBootstrap.configureIfNeeded()
        
        // AdMob 설정
        ADKitBootstrap.start()
        
        // KakaoSDK 설정
        KakaoSDK.initSDK(appKey: Constants.KakaoAPI.key)
        
        // NaverMapSDK 설정
        NMFAuthManager.shared().ncpKeyId = Constants.NaverAPI.key
        
        // 지도 오토 레이아웃 경고 제거
        UserDefaults.standard.set(false, forKey: "_UIConstraintBasedLayoutLogUnsatisfiable")
    }
}

private enum FirebaseCoreBootstrap {
    static func configureIfNeeded() {
        FirebaseConfiguration.shared.setLoggerLevel(.error)
        FirebaseApp.configure()
        Logger.d("FirebaseApp.configure 완료")
    }
}
