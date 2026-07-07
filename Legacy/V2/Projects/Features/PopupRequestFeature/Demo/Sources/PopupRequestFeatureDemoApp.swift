import Data
import Domain
import PopupRequestFeature
import SwiftUI

@main
struct PopupRequestFeatureDemoApp: App {
    init() {
        DIContainer.shared.register(
            AdminUsecaseImpl(adminRepository: AdminRepositoryImpl()),
            for: AdminUsecaseProtocol.self
        )
        DIContainer.shared.register(
            UserUsecaseImpl(userRepository: UserRepositoryImpl()),
            for: UserUsecaseProtocol.self
        )
    }

    var body: some Scene {
        WindowGroup {
            PopupRequestFeatureView()
        }
    }
}
