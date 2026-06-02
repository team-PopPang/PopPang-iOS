import SwiftUI

public struct CustomNavigationBar<Content: View>: View {
    let content: Content
    let hPadding: CGFloat

    public init(
        hPadding: CGFloat = .contentPadding,
        @ViewBuilder content: () -> Content
    ) {
        self.hPadding = hPadding
        self.content = content()
    }

    public var body: some View {
        HStack(spacing: 0) {
            content
        }
        .padding(.top, 10)
        .padding(.horizontal, hPadding)
        .frame(height: 55)
    }
}
