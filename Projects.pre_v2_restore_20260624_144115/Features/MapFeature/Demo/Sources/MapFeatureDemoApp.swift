import Data
import Domain
import MapFeature
import MapFeatureInterface
import SwiftUI

@main
struct MapFeatureDemoApp: App {
    init() {
        DIContainer.shared.register(
            PopupUsecaseImpl(popupRepository: PopupRepositoryImpl()),
            for: PopupUsecaseProtocol.self
        )
    }

    var body: some Scene {
        WindowGroup {
            MapFeatureView(router: MapFeatureDemoRouter())
        }
    }
}

@MainActor
private final class MapFeatureDemoRouter: MapFeatureRouting {
    func route(to route: MapFeatureRoute) {}
}
