import Core
import Foundation
import GoogleSignIn
import KakaoSDKAuth

/// 앱으로 전달된 URL을 분석하여 소셜 로그인 콜백과 딥링크를 처리합니다.
///
/// Google 로그인, Kakao 로그인, Kakao Link, Universal Link를 순서대로 확인하고,
/// 팝업 상세 화면으로 이동해야 하는 경우 팝업 ID를 저장합니다.
@MainActor
struct AppDeepLinkHandler {
    private let storage: DeepLinkStorage

    /// 딥링크 정보를 저장할 저장소를 생성합니다.
    ///
    /// 기본적으로 `UserDefaultsStore`를 사용하며,
    /// 테스트 시 별도의 `KeyValueStoring` 구현체를 주입할 수 있습니다.
    init(store: KeyValueStoring = UserDefaultsStore()) {
        self.storage = DeepLinkStorage(store: store)
    }

    /// 앱으로 전달된 URL을 분석하고 적절한 동작을 수행합니다.
    ///
    /// 처리 가능한 URL이면 `true`, 처리하지 못한 URL이면 `false`를 반환합니다.
    ///
    /// - Parameter url: 앱에 전달된 로그인 콜백 또는 딥링크 URL
    /// - Returns: URL을 성공적으로 처리했으면 `true`, 그렇지 않으면 `false`
    @discardableResult
    func handleIncomingURL(_ url: URL) -> Bool {
        // Google 로그인 인증 콜백 URL을 처리합니다.
        if GIDSignIn.sharedInstance.handle(url) {
            return true
        }

        // Kakao 로그인 인증 콜백 URL인지 확인하고 처리합니다.
        if AuthApi.isKakaoTalkLoginUrl(url) {
            return AuthController.handleOpenUrl(url: url)
        }

        // Kakao Link를 통해 전달된 팝업 상세 딥링크를 처리합니다.
        if url.scheme?.hasPrefix("kakao") == true, url.host == "kakaolink" {
            // 쿼리 파라미터에서 팝업 ID를 추출합니다.
            guard let popupID = URLComponents(url: url, resolvingAgainstBaseURL: false)?
                .queryItems?
                .first(where: { $0.name == "popupId" })?
                .value
            else {
                return false
            }

            // 앱에서 팝업 상세 화면으로 이동할 수 있도록 팝업 ID를 저장합니다.
            storage.savePopupID(popupID)
            return true
        }

        // 웹의 Universal Link를 통해 전달된 팝업 상세 딥링크를 처리합니다.
        if url.absoluteString.hasPrefix(
            ExternalLinkConfig.popupUniversalLinkBaseURLString
        ) {
            // URL의 마지막 경로 값을 팝업 ID로 저장합니다.
            storage.savePopupID(url.lastPathComponent)
            return true
        }

        // 지원하지 않는 URL은 처리하지 않습니다.
        return false
    }
}

