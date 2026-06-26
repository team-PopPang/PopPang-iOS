import Foundation

public struct LocalSessionSnapshot: Equatable, Sendable {
    public let userID: String?
    public let hasCompletedOnboarding: Bool

    public init(
        userID: String?,
        hasCompletedOnboarding: Bool
    ) {
        self.userID = userID
        self.hasCompletedOnboarding = hasCompletedOnboarding
    }

    public var hasAuthenticatedUser: Bool {
        guard let userID else { return false }
        return userID.isEmpty == false
    }
}
