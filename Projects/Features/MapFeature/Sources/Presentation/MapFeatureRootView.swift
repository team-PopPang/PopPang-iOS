import SwiftUI

public struct MapFeatureRootView: View {
    @State private var compound = MapFeatureCompound()

    public init() {}

    public var body: some View {
        MapFeatureView(compound: compound)
    }
}
