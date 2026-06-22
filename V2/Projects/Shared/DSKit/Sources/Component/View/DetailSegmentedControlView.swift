import SwiftUI

public struct DetailSegmentedControlView: View {
    @State private var selectedIndex = 0
    @GestureState private var dragOffset: CGFloat = 0

    private let segments: [String]
    private let views: [AnyView]

    var background: Color
    var foreground: Color
    var height: CGFloat
    var font: UIFont

    public init(
        segments: [String],
        views: [any View],
        background: Color = .gray.opacity(0.3),
        foreground: Color = .blue,
        height: CGFloat = 3,
        font: UIFont = .systemFont(ofSize: 13, weight: .medium)
    ) {
        self.segments = segments
        self.views = views.map { AnyView($0) }
        self.background = background
        self.foreground = foreground
        self.height = height
        self.font = font
    }

    public var body: some View {
        VStack(spacing: 0) {
            HStack(spacing: 0) {
                ForEach(segments.indices, id: \.self) { index in
                    Button {
                        withAnimation(.easeInOut) {
                            selectedIndex = index
                        }
                    } label: {
                        Text(segments[index])
                            .ppStyleFont(font)
                            .foregroundStyle(selectedIndex == index ? foreground : .secondary)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 10)
                    }
                }
            }

            GeometryReader { geometry in
                let width = geometry.size.width / CGFloat(segments.count)

                ZStack(alignment: .leading) {
                    Capsule()
                        .fill(background)
                        .frame(height: height)

                    Capsule()
                        .fill(foreground)
                        .frame(width: width, height: height)
                        .offset(x: CGFloat(selectedIndex) * width)
                        .animation(.easeInOut, value: selectedIndex)
                }
            }
            .frame(height: height)
            .padding(.bottom, 6)

            GeometryReader { geometry in
                HStack(spacing: 0) {
                    ForEach(views.indices, id: \.self) { index in
                        views[index]
                            .frame(width: geometry.size.width)
                    }
                }
                .offset(x: -CGFloat(selectedIndex) * geometry.size.width + dragOffset)
                .animation(.easeInOut, value: selectedIndex)
                .gesture(
                    DragGesture()
                        .updating($dragOffset) { value, state, _ in
                            state = value.translation.width
                        }
                        .onEnded { value in
                            let threshold = geometry.size.width / 4
                            if value.translation.width < -threshold {
                                selectedIndex = min(selectedIndex + 1, views.count - 1)
                            } else if value.translation.width > threshold {
                                selectedIndex = max(selectedIndex - 1, 0)
                            }
                        }
                )
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }
    }
}
