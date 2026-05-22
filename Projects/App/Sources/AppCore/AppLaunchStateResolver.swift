import Coordinator
import Foundation

struct AppLaunchStateResolver: Sendable {
    func resolve(snapshot: AppSessionSnapshot) -> RootDestination {
        if snapshot.hasAuthenticatedUser {
            return .main
        }

        if snapshot.hasCompletedOnboarding {
            return .auth
        }

        return .onboarding
    }
}
