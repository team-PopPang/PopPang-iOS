import SwiftUI

public extension ShapeStyle where Self == Color {
    static var random: Color {
        Color(
            red: .random(in: 0...1),
            green: .random(in: 0...1),
            blue: .random(in: 0...1)
        )
    }
}

private struct DebugDiffKey: Equatable {
    let values: [AnyHashable]
}

private struct DebugDiffRandomBackgroundModifier<Key: Equatable>: ViewModifier {
    let diffKey: Key
    @State private var color: Color = .random

    func body(content: Content) -> some View {
        content
            .background(color.opacity(0.25))
            .overlay {
                RoundedRectangle(cornerRadius: 0)
                    .stroke(color, lineWidth: 1)
            }
            .onChange(of: diffKey) { _, _ in
                color = .random
            }
    }
}

public extension View {
    func debugBodyRandomBackground() -> some View {
        let color = Color.random
        return background(color.opacity(0.25))
            .overlay {
                RoundedRectangle(cornerRadius: 0)
                    .stroke(color, lineWidth: 1)
            }
    }

    func debugDiffRandomBackground(
        _ values: AnyHashable...
    ) -> some View {
        modifier(
            DebugDiffRandomBackgroundModifier(
                diffKey: DebugDiffKey(values: values)
            )
        )
    }
}
