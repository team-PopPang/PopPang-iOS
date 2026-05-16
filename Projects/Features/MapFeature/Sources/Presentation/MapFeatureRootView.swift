import SwiftUI

public struct MapFeatureRootView: View {
    public init() {}

    public var body: some View {
        MapFeatureView(
            store: MapFeatureStore()
        )
    }
}
