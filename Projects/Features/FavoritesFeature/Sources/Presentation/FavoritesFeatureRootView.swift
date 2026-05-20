import SwiftUI

public struct FavoritesFeatureRootView: View {
    @State private var compound = FavoritesFeatureCompound()

    public init() {}

    public var body: some View {
        FavoritesFeatureView(compound: compound)
    }
}
