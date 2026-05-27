import Core
import KakaoSDKCommon
import NMapsMap
import UIKit

enum AppSDKInitializer {
    static func configure() {
        FirebaseCoreBridge.configureIfNeeded()
        KakaoSDK.initSDK(appKey: Constants.KakaoAPI.key)
        NMFAuthManager.shared().ncpKeyId = Constants.NaverAPI.key
        UserDefaults.standard.set(false, forKey: "_UIConstraintBasedLayoutLogUnsatisfiable")
    }
}

private enum FirebaseCoreBridge {
    static func configureIfNeeded() {
        guard let appClass = NSClassFromString("FIRApp") as AnyObject? else {
            return
        }

        let defaultApp = appClass
            .perform(NSSelectorFromString("defaultApp"))?
            .takeUnretainedValue()

        guard defaultApp == nil else { return }

        _ = appClass.perform(NSSelectorFromString("configure"))
    }
}
