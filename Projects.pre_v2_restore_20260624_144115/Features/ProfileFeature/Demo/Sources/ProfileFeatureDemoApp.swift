import Data
import Domain
import ProfileFeature
import ProfileFeatureInterface
import SwiftUI

@main
struct ProfileFeatureDemoApp: App {
    init() {
        DIContainer.shared.register(
            UserUsecaseImpl(userRepository: UserRepositoryImpl()),
            for: UserUsecaseProtocol.self
        )
    }

    var body: some Scene {
        WindowGroup {
            ProfileFeatureView(router: ProfileFeatureDemoRouter())
        }
    }
}

@MainActor
private final class ProfileFeatureDemoRouter: ProfileFeatureRouting {
    func route(to route: ProfileFeatureRoute) {}
}
