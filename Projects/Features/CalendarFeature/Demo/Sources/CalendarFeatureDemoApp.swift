import CalendarFeature
import Data
import Domain
import SwiftUI

@main
struct CalendarFeatureDemoApp: App {
    init() {
        DIContainer.shared.register(
            PopupUsecaseImpl(popupRepository: PopupRepositoryImpl()),
            for: PopupUsecaseProtocol.self
        )
    }

    var body: some Scene {
        WindowGroup {
            CalendarFeatureView()
        }
    }
}
