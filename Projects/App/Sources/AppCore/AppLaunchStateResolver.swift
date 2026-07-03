import Core
import Foundation

struct AppLaunchStateResolver: Sendable {
    func resolve(
        snapshot: LocalSessionSnapshot,
        session: UserSession
    ) -> AppRootDestination {
        guard let user = session.user else { return .onboarding }
        return user.nickname == nil ? .register : .main
    }
}
