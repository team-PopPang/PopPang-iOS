import SwiftUI

public struct ProfileFeatureRootView: View {
    @State private var compound = ProfileFeatureCompound()

    public init() {}

    public var body: some View {
        ProfileFeatureView(compound: compound)
    }
}
