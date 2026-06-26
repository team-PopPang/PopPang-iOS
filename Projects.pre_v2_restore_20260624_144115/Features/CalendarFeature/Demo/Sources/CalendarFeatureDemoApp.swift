import CalendarFeature
import CalendarFeatureInterface
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
            CalendarFeatureView(router: CalendarFeatureDemoRouter())
        }
    }
}

@MainActor
private final class CalendarFeatureDemoRouter: CalendarFeatureRouting {
    func route(to route: CalendarFeatureRoute) {}
}
