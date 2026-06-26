import AlertFeature
import AlertFeatureInterface
import Data
import Domain
import SwiftUI

@main
struct AlertFeatureDemoApp: App {
    init() {
        DIContainer.shared.register(
            PopupUsecaseImpl(popupRepository: PopupRepositoryImpl()),
            for: PopupUsecaseProtocol.self
        )
        DIContainer.shared.register(
            UserUsecaseImpl(userRepository: UserRepositoryImpl()),
            for: UserUsecaseProtocol.self
        )
    }

    var body: some Scene {
        WindowGroup {
            AlertFeatureView(router: AlertFeatureDemoRouter())
        }
    }
}

@MainActor
private final class AlertFeatureDemoRouter: AlertFeatureRouting {
    func route(to route: AlertFeatureRoute) {}
}
