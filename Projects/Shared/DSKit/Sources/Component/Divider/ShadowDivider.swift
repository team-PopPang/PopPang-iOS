import SwiftUI

public struct ShadowDivider: View {
    public init() {}

    public var body: some View {
        LinearGradient(
            gradient: Gradient(
                colors: [
                    Color.black.opacity(0.1),
                    Color.black.opacity(0.0),
                ]
            ),
            startPoint: .top,
            endPoint: .bottom
        )
        .frame(height: 3)
        .blur(radius: 2)
        .allowsHitTesting(false)
    }
}
