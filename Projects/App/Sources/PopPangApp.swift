import Coordinator
import SwiftUI

@main
struct PopPangApp: App {
    @UIApplicationDelegateAdaptor(PopPangAppDelegate.self) private var appDelegate

    private let bootstrap = AppBootstrap.live()
    private let deepLinkHandler = AppDeepLinkHandler()

    init() {
        AppSDKInitializer.configure()
    }

    var body: some Scene {
        WindowGroup {
            RootCoordinatorView(coordinator: bootstrap.makeRootCoordinator())
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
