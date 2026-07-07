import Core
import Foundation
import GoogleSignIn
import KakaoSDKAuth

@MainActor
struct AppDeepLinkHandler {
    private let storage: AppSessionStorage

    init(store: KeyValueStoring = UserDefaultsStore()) {
        self.storage = AppSessionStorage(store: store)
    }

    @discardableResult
    func handleIncomingURL(_ url: URL) -> Bool {
        if GIDSignIn.sharedInstance.handle(url) {
            return true
        }

        if AuthApi.isKakaoTalkLoginUrl(url) {
            return AuthController.handleOpenUrl(url: url)
        }

        if url.scheme?.hasPrefix("kakao") == true, url.host == "kakaolink" {
            guard let popupID = URLComponents(url: url, resolvingAgainstBaseURL: false)?
                .queryItems?
                .first(where: { $0.name == "popupId" })?
                .value
            else {
                return false
            }

            storage.saveDeepLinkPopupID(popupID)
            return true
        }

        if url.absoluteString.hasPrefix(ExternalLinkConfig.popupUniversalLinkBaseURLString) {
            storage.saveDeepLinkPopupID(url.lastPathComponent)
            return true
        }

        return false
    }
}
