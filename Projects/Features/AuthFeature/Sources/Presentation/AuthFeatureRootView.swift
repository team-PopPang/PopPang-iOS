import SwiftUI

public struct AuthFeatureRootView: View {
    @State private var compound = AuthFeatureCompound()

    public init() {}

    public var body: some View {
        AuthFeatureView(compound: compound)
    }
}
