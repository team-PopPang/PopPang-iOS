import SwiftUI

public struct AuthFeatureRootView: View {
    public init() {}

    public var body: some View {
        AuthFeatureView(
            store: AuthFeatureStore()
        )
    }
}
