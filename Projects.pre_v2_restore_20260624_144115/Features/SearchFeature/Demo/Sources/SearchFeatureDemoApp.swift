import Data
import Domain
import SearchFeature
import SearchFeatureInterface
import SwiftUI

@main
struct SearchFeatureDemoApp: App {
    init() {
        DIContainer.shared.register(
            PopupUsecaseImpl(popupRepository: PopupRepositoryImpl()),
            for: PopupUsecaseProtocol.self
        )
    }

    var body: some Scene {
        WindowGroup {
            SearchFeatureView(router: SearchFeatureDemoRouter())
        }
    }
}

@MainActor
private final class SearchFeatureDemoRouter: SearchFeatureRouting {
    func route(to route: SearchFeatureRoute) {}
}
