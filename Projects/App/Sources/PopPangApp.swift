import Coordinator
import SwiftUI

@main
struct PopPangApp: App {
    private let bootstrap = AppBootstrap.live()

    var body: some Scene {
        WindowGroup {
            RootCoordinatorView(coordinator: bootstrap.makeRootCoordinator())
        }
    }
}
