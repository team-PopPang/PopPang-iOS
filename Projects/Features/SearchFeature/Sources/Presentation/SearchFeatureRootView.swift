import SwiftUI

public struct SearchFeatureRootView: View {
    @State private var compound = SearchFeatureCompound()

    public init() {}

    public var body: some View {
        SearchFeatureView(compound: compound)
    }
}
