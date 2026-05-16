import SwiftUI

public struct ReviewFeatureRootView: View {
    public init() {}

    public var body: some View {
        ReviewFeatureView(
            store: ReviewFeatureStore()
        )
    }
}
