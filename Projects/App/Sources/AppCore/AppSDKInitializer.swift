import Core
import DSKit
import FirebaseCore
import GoogleMobileAds
import KakaoSDKCommon
import NMapsMap
import UIKit
import Airbridge

enum AppSDKInitializer {
    private static var isConfigured = false

    static func configure() {
        guard isConfigured == false else { return }
        isConfigured = true

        UITabBar.configureAppearance()
        UINavigationBar.configureAppearance()
        FirebaseCoreBootstrap.configureIfNeeded()
        AirBridgeBootstrap.configureIfNeeded()
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
        .setAutoDetermineTrackingAuthorizationTimeout(second: 0)
        .build()

        Airbridge.initializeSDK(option: option)
        Logger.d("Airbridge.initializeSDK 완료")
    }
}
