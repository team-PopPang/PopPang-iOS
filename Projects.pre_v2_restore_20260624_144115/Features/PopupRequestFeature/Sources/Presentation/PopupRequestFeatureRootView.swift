import PopupRequestFeatureInterface
import SwiftUI

public struct PopupRequestFeatureRootView: View {
    public init() {}

    public var body: some View {
        PopupRequestFeatureView(router: PopupRequestFeatureRootRouter())
            .navigationTitle("PopupRequest Root")
    }
}

@MainActor
private final class PopupRequestFeatureRootRouter: PopupRequestFeatureRouting {
    func route(to route: PopupRequestFeatureRoute) {}
}
