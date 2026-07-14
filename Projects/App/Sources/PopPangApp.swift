import ComposableArchitecture
import SwiftUI

@main
struct PopPangApp: App {
    @UIApplicationDelegateAdaptor(PopPangAppDelegate.self) private var appDelegate

    private let deepLinkHandler: AppDeepLinkHandler
    @State private var store: StoreOf<AppFeature>

    init() {
        // 라이브러리 초기화
        AppSDKInitializer.configure()
        
        // 의존성 그래프 생성
        let bootstrap = AppBootstrap.live()

        // Keep one root store for the app lifetime so session and navigation state survive body updates.
        self._store = State(initialValue: bootstrap.makeAppStore())
        
        // 앱으로 전달된 URL을 분석하여 소셜 로그인 콜백과 딥링크를 처리
        self.deepLinkHandler = AppDeepLinkHandler()
    }

    var body: some Scene {
        WindowGroup {
            AppRootFlowView(store: store)
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
