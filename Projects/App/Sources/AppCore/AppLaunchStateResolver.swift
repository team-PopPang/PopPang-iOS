import Core
import Foundation

struct AppLaunchStateResolver: Sendable {
    func resolve(
        snapshot: LocalSessionSnapshot,
        session: SessionState
    ) -> AppRootDestination {
        if snapshot.hasCompletedOnboarding == false {
            return .onboarding
        }

        guard let user = session.user else { return .auth }
        return user.nickname == nil ? .register : .main
    }
}
