import SwiftUI

@MainActor
public protocol Coordinator: AnyObject {
    associatedtype Route: Codable & Hashable
    associatedtype Destination: View
    associatedtype RootView: View

    var navigationController: NavigationController { get }

    @ViewBuilder
    func coordinate(_ route: Route) -> Destination

    @ViewBuilder
    var rootView: RootView { get }
}
