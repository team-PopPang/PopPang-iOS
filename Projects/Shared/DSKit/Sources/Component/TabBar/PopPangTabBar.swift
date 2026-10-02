import SwiftUI

/// 탭바를 어떤 모양으로 그릴지 정한다.
public enum PopPangTabBarStyle: Sendable {
    /// 시스템 `TabView` 탭바. Xcode 27(iOS 27 SDK)로 빌드하면 Liquid Glass로 그려진다.
    case system
    /// `PopPangTabBar`로 그리는 기존(iOS 18까지의) 모양.
    case classic
}

public enum PopPangTabBarMetrics {
    /// 기존 시스템 탭바와 같은 콘텐츠 높이. 하단 safe area는 포함하지 않는다.
    public static let height: CGFloat = 49
    /// 시스템 `tabItem`에 넘기는 아이콘 크기. 시스템 탭바는 이 frame을 무시하고 에셋 원래 크기로 그린다.
    static let iconSize: CGFloat = 25
    /// 기존 시스템 탭바에서 잰 아이콘·탭 이름 중심의 세로 위치(탭바 윗변 기준).
    static let iconCenterY: CGFloat = 18.84
    static let iconOffsetX: CGFloat = -0.5
    static let titleCenterY: CGFloat = 41.84
    static let shadowHeight: CGFloat = 8
}

/// 시스템 탭바를 숨기고 `PopPangTabBar`를 붙일지, 시스템 탭바를 그대로 쓸지 고를 수 있는 `TabView`.
/// 탭 화면은 `@Environment(\.popPangTabBarStyle)`로 현재 스타일을 읽는다.
public struct PopPangTabView<Tab: Hashable, Content: View>: View {
    @Binding private var selection: Tab
    private let tabs: [Tab]
    private let style: PopPangTabBarStyle
    private let title: (Tab) -> String
    private let image: (Tab, _ isSelected: Bool) -> Image
    private let content: (Tab) -> Content

    public init(
        selection: Binding<Tab>,
        tabs: [Tab],
        style: PopPangTabBarStyle,
        title: @escaping (Tab) -> String,
        image: @escaping (Tab, _ isSelected: Bool) -> Image,
        @ViewBuilder content: @escaping (Tab) -> Content
    ) {
        self._selection = selection
        self.tabs = tabs
        self.style = style
        self.title = title
        self.image = image
        self.content = content
    }

    public var body: some View {
        TabView(selection: $selection) {
            ForEach(tabs, id: \.self) { tab in
                content(tab)
                    .tabItem {
                        image(tab, selection == tab)
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(width: PopPangTabBarMetrics.iconSize, height: PopPangTabBarMetrics.iconSize)
                        Text(title(tab))
                    }
                    .tag(tab)
                    .toolbar(style == .classic ? .hidden : .automatic, for: .tabBar)
            }
        }
        .safeAreaInset(edge: .bottom, spacing: 0) {
            if style == .classic {
                PopPangTabBar(tabs: tabs, selection: $selection, title: title, image: image)
            }
        }
        .environment(\.popPangTabBarStyle, style)
    }
}

/// `UITabBar.configureAppearance()`가 만들던 기존 시스템 탭바와 같은 모양을 SwiftUI로 그린다.
public struct PopPangTabBar<Tab: Hashable>: View {
    @Binding private var selection: Tab
    private let tabs: [Tab]
    private let title: (Tab) -> String
    private let image: (Tab, _ isSelected: Bool) -> Image

    public init(
        tabs: [Tab],
        selection: Binding<Tab>,
        title: @escaping (Tab) -> String,
        image: @escaping (Tab, _ isSelected: Bool) -> Image
    ) {
        self.tabs = tabs
        self._selection = selection
        self.title = title
        self.image = image
    }

    public var body: some View {
        HStack(spacing: 0) {
            ForEach(tabs, id: \.self) { tab in
                item(for: tab, isSelected: selection == tab)
            }
        }
        .frame(height: PopPangTabBarMetrics.height)
        .background {
            Color.subWhite
                .ignoresSafeArea(edges: .bottom)
        }
        .overlay(alignment: .top) {
            // 기존 탭바의 shadowImage와 같다. 윗변 바로 위 8pt를 투명에서 검정 7%로 칠한다.
            LinearGradient(colors: [.clear, .black.opacity(0.07)], startPoint: .top, endPoint: .bottom)
                .frame(height: PopPangTabBarMetrics.shadowHeight)
                .offset(y: -PopPangTabBarMetrics.shadowHeight)
                .allowsHitTesting(false)
        }
        .ignoresSafeArea(.keyboard, edges: .bottom)
    }

    private func item(for tab: Tab, isSelected: Bool) -> some View {
        Button {
            selection = tab
        } label: {
            // 기존 시스템 탭바처럼 아이콘을 에셋 원래 색·원래 크기로 그리고, 중심 위치를 고정한다.
            // 높이가 0인 frame은 내용을 윗변에 중심 맞춰 두므로, offset이 곧 중심의 세로 위치가 된다.
            ZStack(alignment: .top) {
                image(tab, isSelected)
                    .renderingMode(.original)
                    .frame(height: 0)
                    .offset(x: PopPangTabBarMetrics.iconOffsetX, y: PopPangTabBarMetrics.iconCenterY)

                Text(title(tab))
                    .font(.scdream(isSelected ? .bold : .light, size: 10))
                    .foregroundStyle(isSelected ? Color.black : Color(uiColor: .gray))
                    .frame(height: 0)
                    .offset(y: PopPangTabBarMetrics.titleCenterY)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityAddTraits(isSelected ? .isSelected : [])
    }
}

private struct PopPangTabBarStyleKey: EnvironmentKey {
    static let defaultValue: PopPangTabBarStyle = .system
}

public extension EnvironmentValues {
    /// 탭 화면을 감싼 `PopPangTabView`의 탭바 스타일.
    var popPangTabBarStyle: PopPangTabBarStyle {
        get { self[PopPangTabBarStyleKey.self] }
        set { self[PopPangTabBarStyleKey.self] = newValue }
    }
}
