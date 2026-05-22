import Foundation
import Domain

@MainActor
public protocol RootCoordinating: AnyObject {
    func showLaunch()
    func showOnboarding()
    func showAuthFlow()
    func showMainFlow()
    func completeOnboarding()
    func completeAuthentication(userID: String)
    func completeAuthentication(user: User)
    func logout()
}
