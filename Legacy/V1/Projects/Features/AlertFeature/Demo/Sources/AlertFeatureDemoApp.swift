import AlertFeature
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
            AlertFeatureView()
        }
    }
}
