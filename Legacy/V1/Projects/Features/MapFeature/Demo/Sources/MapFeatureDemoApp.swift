import Data
import Domain
import MapFeature
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
            MapFeatureView()
        }
    }
}
