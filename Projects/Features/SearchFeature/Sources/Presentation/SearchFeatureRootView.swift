import SwiftUI

public struct SearchFeatureRootView: View {
    public init() {}

    public var body: some View {
        SearchFeatureView(
            store: SearchFeatureStore()
        )
    }
}
