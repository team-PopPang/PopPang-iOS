import Foundation

@MainActor
public protocol RootCoordinating: AnyObject {
    func showLaunch()
    func showOnboarding()
    func showAuthFlow()
    func showMainFlow()
}
