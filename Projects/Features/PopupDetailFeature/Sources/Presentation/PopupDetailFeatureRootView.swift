import SwiftUI

public struct PopupDetailFeatureRootView: View {
    public init() {}

    public var body: some View {
        PopupDetailFeatureView(
            store: PopupDetailFeatureStore()
        )
    }
}
