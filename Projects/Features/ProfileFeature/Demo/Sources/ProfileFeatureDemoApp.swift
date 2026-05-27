import Data
import Domain
import ProfileFeature
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
            ProfileFeatureView()
        }
    }
}
