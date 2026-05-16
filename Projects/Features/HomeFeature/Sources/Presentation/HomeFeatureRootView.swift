import SwiftUI

public struct HomeFeatureRootView: View {
    public init() {}

    public var body: some View {
        HomeFeatureView(
            store: HomeFeatureStore()
        )
    }
}
