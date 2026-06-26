import Data
import Domain
import FavoritesFeature
import FavoritesFeatureInterface
import SwiftUI

@main
struct FavoritesFeatureDemoApp: App {
    init() {
        DIContainer.shared.register(
            PopupUsecaseImpl(popupRepository: PopupRepositoryImpl()),
            for: PopupUsecaseProtocol.self
        )
    }

    var body: some Scene {
        WindowGroup {
            FavoritesFeatureView(router: FavoritesFeatureDemoRouter())
        }
    }
}

@MainActor
private final class FavoritesFeatureDemoRouter: FavoritesFeatureRouting {
    func route(to route: FavoritesFeatureRoute) {}
}
