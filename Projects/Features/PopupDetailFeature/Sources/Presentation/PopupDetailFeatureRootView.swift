import SwiftUI

public struct PopupDetailFeatureRootView: View {
    @State private var compound = PopupDetailFeatureCompound()

    public init() {}

    public var body: some View {
        PopupDetailFeatureView(compound: compound)
    }
}
