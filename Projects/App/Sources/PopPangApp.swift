import SwiftUI

@main
struct PopPangApp: App {
    @UIApplicationDelegateAdaptor(PopPangAppDelegate.self) private var appDelegate

    private let bootstrap: AppBootstrap
    private let deepLinkHandler: AppDeepLinkHandler

    init() {
        AppSDKInitializer.configure()
        self.bootstrap = AppBootstrap.live()
        self.deepLinkHandler = AppDeepLinkHandler()
    }

    var body: some Scene {
        WindowGroup {
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
