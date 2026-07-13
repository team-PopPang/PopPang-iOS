import SwiftUI

@main
struct PopPangApp: App {
    @UIApplicationDelegateAdaptor(PopPangAppDelegate.self) private var appDelegate

    private let bootstrap: AppBootstrap
    private let deepLinkHandler: AppDeepLinkHandler

    init() {
        // 라이브러리 초기화
        AppSDKInitializer.configure()
        
        // 의존성 그래프 생성
        self.bootstrap = AppBootstrap.live()
        
        // 앱으로 전달된 URL을 분석하여 소셜 로그인 콜백과 딥링크를 처리
        self.deepLinkHandler = AppDeepLinkHandler()
    }

    var body: some Scene {
        WindowGroup {
            // makeAppStore(): 앱의 최상위 TCA Store를 생성
            AppRootFlowView(store: bootstrap.makeAppStore())
                .versionUpdateAlert()
                .onOpenURL { url in
                    deepLinkHandler.handleIncomingURL(url)
                }
                .onContinueUserActivity(NSUserActivityTypeBrowsingWeb) { activity in
                    guard let url = activity.webpageURL else { return }
                    deepLinkHandler.handleIncomingURL(url)
                }
        }
    }
}
