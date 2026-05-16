import SwiftUI

public struct FavoritesFeatureRootView: View {
    public init() {}

    public var body: some View {
        FavoritesFeatureView(
            store: FavoritesFeatureStore()
        )
    }
}
