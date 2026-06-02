import Data
import Domain
import SearchFeature
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
            SearchFeatureView()
        }
    }
}
