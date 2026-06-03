import Data
import Domain
import PopupReportFeature
import SwiftUI

@main
struct PopupReportFeatureDemoApp: App {
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
            PopupReportFeatureView()
        }
    }
}
