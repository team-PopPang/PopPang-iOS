import SwiftUI

public struct ProfileFeatureRootView: View {
    public init() {}

    public var body: some View {
        ProfileFeatureView(
            store: ProfileFeatureStore()
        )
    }
}
