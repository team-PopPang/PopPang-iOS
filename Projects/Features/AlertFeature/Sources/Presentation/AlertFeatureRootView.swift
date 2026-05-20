import SwiftUI

public struct AlertFeatureRootView: View {
    @State private var compound = AlertFeatureCompound()

    public init() {}

    public var body: some View {
        AlertFeatureView(compound: compound)
    }
}
