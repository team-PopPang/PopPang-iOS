import Core
import Foundation

struct AppLaunchStateResolver: Sendable {
    /// V2 세션 복구는 가입을 마친 사용자만 돌려주므로, 사용자가 있으면 메인으로 간다.
    func resolve(
        snapshot: LocalSessionSnapshot,
        session: UserSession
    ) -> AppRootDestination {
        session.user == nil ? .onboarding : .main
    }
}
