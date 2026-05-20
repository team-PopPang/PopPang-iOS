import SwiftUI

public struct SegmentedControlView: View {
    @State private var selectedIndex = 0
    private let anyViews: [AnyView]

    let segments: [String]
    var background: Color
    var foreground: Color
    var height: CGFloat
    var font: UIFont

    public init(
        segments: [String],
        views: [any View],
        background: Color = .gray.opacity(0.3),
        foreground: Color = .blue,
        height: CGFloat = 4,
        font: UIFont = .scdream(.medium, size: 12)
    ) {
        self.segments = segments
        self.anyViews = views.map { AnyView($0) }
        self.background = background
        self.foreground = foreground
        self.height = height
        self.font = font
    }

    public var body: some View {
        VStack(spacing: 0) {
            HStack {
                ForEach(segments.indices, id: \.self) { index in
                    Button {
                        withAnimation(.easeInOut(duration: 0.25)) {
                            selectedIndex = index
                        }
                    } label: {
                        Text(segments[index])
                            .ppStyleFont(font)
                            .foregroundStyle(selectedIndex == index ? foreground : background)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 10)
                    }
                }
            }

            GeometryReader { geometry in
                let segmentWidth = geometry.size.width / CGFloat(segments.count)
                ZStack(alignment: .leading) {
                    Color.mainGray5.frame(height: 2)
                    Capsule()
                        .fill(foreground)
                        .frame(width: segmentWidth, height: height)
                        .offset(x: CGFloat(selectedIndex) * segmentWidth)
                        .animation(.easeInOut(duration: 0.25), value: selectedIndex)
                }
            }
            .frame(height: height)

            TabView(selection: $selectedIndex) {
                ForEach(anyViews.indices, id: \.self) { index in
                    anyViews[index]
                        .tag(index)
                }
            }
            .tabViewStyle(.page(indexDisplayMode: .never))
            .ignoresSafeArea(edges: .bottom)
        }
    }
}
