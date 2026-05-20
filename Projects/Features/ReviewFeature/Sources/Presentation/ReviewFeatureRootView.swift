import SwiftUI

public struct ReviewFeatureRootView: View {
    @State private var compound = ReviewFeatureCompound()

    public init() {}

    public var body: some View {
        ReviewFeatureView(compound: compound)
    }
}
