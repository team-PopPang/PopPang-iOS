import SwiftUI

public struct MapSheetModifier: ViewModifier {
    let bottomPadding: CGFloat

    public init(bottomPadding: CGFloat = 49) {
        self.bottomPadding = bottomPadding
    }

    public func body(content: Content) -> some View {
        content.background(MapSheetBackgroundView(bottomPadding: bottomPadding))
    }
}

public extension View {
    func mapSheet(_ bottomPadding: CGFloat = 49) -> some View {
        modifier(MapSheetModifier(bottomPadding: bottomPadding))
    }
}

private extension UIView {
    var viewBeforeWindow: UIView? {
        if let superview, superview is UIWindow {
            return self
        }
        return superview?.viewBeforeWindow
    }

    var allSubView: [UIView] {
        subviews.flatMap { [$0] + $0.subviews }
    }
}

private struct MapSheetBackgroundView: UIViewRepresentable {
    var bottomPadding: CGFloat

    func makeCoordinator() -> Coordinator {
        Coordinator()
    }

    func makeUIView(context: Context) -> UIView {
        UIView()
    }

    func updateUIView(_ uiView: UIView, context: Context) {
        DispatchQueue.main.async {
            guard !context.coordinator.isMasked,
                  let rootView = uiView.viewBeforeWindow else { return }

            let safeArea = rootView.safeAreaInsets
            rootView.frame = .init(
                origin: .zero,
                size: .init(
                    width: rootView.frame.width,
                    height: rootView.frame.height - (bottomPadding + safeArea.bottom)
                )
            )

            rootView.clipsToBounds = true

            for view in rootView.subviews {
                view.layer.shadowColor = UIColor.clear.cgColor
                if view.layer.animationKeys() != nil,
                   let cornerRadiusView = view.allSubView.first(where: {
                       $0.layer.animationKeys()?.contains("cornerRadius") ?? false
                   }) {
                    cornerRadiusView.layer.maskedCorners = []
                }
            }

            context.coordinator.isMasked = true
        }
    }

    final class Coordinator: NSObject {
        var isMasked = false
    }
}
