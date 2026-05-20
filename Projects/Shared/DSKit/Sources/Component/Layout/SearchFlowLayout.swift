import SwiftUI

public struct SearchFlowButton: View {
    let title: String
    let action: () -> Void
    let onRemove: () -> Void

    public init(
        title: String,
        action: @escaping () -> Void,
        onRemove: @escaping () -> Void
    ) {
        self.title = title
        self.action = action
        self.onRemove = onRemove
    }

    public var body: some View {
        Button(action: action) {
            HStack(spacing: 20) {
                Text(title)
                    .font(.scdream(.regular, size: 9))
                    .foregroundStyle(Color.mainBlack)

                Button(action: onRemove) {
                    Image("removeBtn")
                        .resizable()
                        .frame(width: 25, height: 25)
                        .foregroundStyle(Color.mainBlack)
                        .padding(5)
                }
            }
            .padding(.leading, 14)
            .background {
                RoundedRectangle(cornerRadius: 20)
                    .stroke(lineWidth: 1.5)
                    .fill(Color.mainGray5)
            }
        }
    }
}

public struct SearchFlowLayout: Layout {
    public init() {}

    public func sizeThatFits(
        proposal: ProposedViewSize,
        subviews: Subviews,
        cache: inout ()
    ) -> CGSize {
        var width: CGFloat = 0
        var height: CGFloat = 0
        var lineHeight: CGFloat = 0
        let maxWidth = proposal.width ?? .infinity

        for subview in subviews {
            let size = subview.sizeThatFits(.unspecified)

            if width + size.width > maxWidth {
                width = 0
                height += lineHeight
                lineHeight = 0
            }

            lineHeight = max(lineHeight, size.height)
            width += size.width
        }

        height += lineHeight
        return CGSize(width: maxWidth, height: height)
    }

    public func placeSubviews(
        in bounds: CGRect,
        proposal: ProposedViewSize,
        subviews: Subviews,
        cache: inout ()
    ) {
        var x: CGFloat = bounds.minX
        var y: CGFloat = bounds.minY
        var lineHeight: CGFloat = 0
        let maxWidth = bounds.width

        for subview in subviews {
            let size = subview.sizeThatFits(.unspecified)

            if x + size.width > bounds.minX + maxWidth {
                x = bounds.minX
                y += lineHeight
                lineHeight = 0
            }

            subview.place(at: CGPoint(x: x, y: y), proposal: .unspecified)
            x += size.width
            lineHeight = max(lineHeight, size.height)
        }
    }
}
