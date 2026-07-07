import Foundation

struct AppSessionSnapshot: Equatable, Sendable {
    let userID: String?
    let hasCompletedOnboarding: Bool
    let fcmToken: String?
    let deepLinkPopupID: String?

    var hasAuthenticatedUser: Bool {
        guard let userID else { return false }
        return userID.isEmpty == false
    }
}
