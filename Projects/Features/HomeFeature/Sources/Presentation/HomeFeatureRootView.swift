import SwiftUI

public struct HomeFeatureRootView: View {
    private let navigator: (any HomeFeatureNavigating)?
    @State private var compound = HomeFeatureCompound()

    public init(navigator: (any HomeFeatureNavigating)? = nil) {
        self.navigator = navigator
    }

    public var body: some View {
        HomeFeatureView(compound: compound)
            .onChange(of: compound.state.route) { _, route in
                guard let route else { return }

                switch route {
                case .search:
                    navigator?.showSearch()
                case .popupDetail:
                    navigator?.showPopupDetail()
                }

                compound.send(.routeHandled)
            }
    }
}
