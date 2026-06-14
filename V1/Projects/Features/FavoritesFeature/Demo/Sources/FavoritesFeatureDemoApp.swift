import Data
import Domain
import FavoritesFeature
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
            FavoritesFeatureView()
        }
    }
}
