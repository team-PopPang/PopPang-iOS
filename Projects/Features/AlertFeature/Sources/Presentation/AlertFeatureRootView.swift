import SwiftUI

public struct AlertFeatureRootView: View {
    public init() {}

    public var body: some View {
        AlertFeatureView(
            store: AlertFeatureStore()
        )
    }
}
