import Core
import DSKit
import FirebaseCore
import GoogleMobileAds
import KakaoSDKCommon
import NMapsMap
import UIKit
import Airbridge
import AppTrackingTransparency

enum AppSDKInitializer {
    private static var isConfigured = false

    static func configure() {
        guard isConfigured == false else { return }
        isConfigured = true

        UITabBar.configureAppearance()
        UINavigationBar.configureAppearance()
        FirebaseCoreBootstrap.configureIfNeeded()

        // Airbridge는 먼저 초기화하되, ATT 응답을 기다릴 수 있도록 timeout을 30초로 둠
        AirBridgeBootstrap.configureIfNeeded()

        // 앱이 active 상태가 되었을 때 ATT 프롬프트 요청
        ATTBootstrap.requestWhenAppBecomesActiveOnce()

        MobileAds.shared.start(completionHandler: nil)
        KakaoSDK.initSDK(appKey: Constants.KakaoAPI.key)
        NMFAuthManager.shared().ncpKeyId = Constants.NaverAPI.key
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

private enum AirBridgeBootstrap {
    static func configureIfNeeded() {
        let option = AirbridgeOptionBuilder(
            name: Constants.Airbridge.appName,
            token: Constants.Airbridge.sdkToken
        )
        .setAutoDetermineTrackingAuthorizationTimeout(second: 30)
        .build()

        Airbridge.initializeSDK(option: option)
        Logger.d("Airbridge.initializeSDK 완료")
    }
}

private enum ATTBootstrap {
    private static var observer: NSObjectProtocol?

    static func requestWhenAppBecomesActiveOnce() {
        guard ATTrackingManager.trackingAuthorizationStatus == .notDetermined else {
            return
        }

        observer = NotificationCenter.default.addObserver(
            forName: UIApplication.didBecomeActiveNotification,
            object: nil,
            queue: .main
        ) { _ in
            ATTrackingManager.requestTrackingAuthorization { status in
                Logger.d("ATT authorization status: \(status.rawValue)")
            }

            if let currentObserver = Self.observer {
                NotificationCenter.default.removeObserver(currentObserver)
                Self.observer = nil
            }
        }
    }
}
