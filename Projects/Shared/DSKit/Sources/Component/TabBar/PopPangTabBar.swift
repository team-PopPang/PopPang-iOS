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
    /// 탭별로 이미 고른 탭을 다시 누른 횟수. 탭 화면은 `onPopPangTabReselect`로 이 값이 늘어나는 것을 받는다.
    /// `.classic`의 `PopPangTabBar`만 다시 누름을 알린다. `.system`은 SwiftUI `TabView`가 같은 탭을 다시 골랐을 때
    /// 알려 준다는 보장이 없어(값을 다시 쓰지 않거나, 나타날 때 같은 값을 쓰기도 한다) 지원하지 않는다.
    @State private var reselectCounts: [Tab: Int] = [:]
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
                    .environment(\.popPangTabReselectCount, reselectCounts[tab, default: 0])
                    // TabView는 바깥에서 더한 safe area를 탭 화면에 전달하지 않는다.
                    // 시스템 탭바처럼 탭 화면의 하단 safe area에 커스텀 탭바 높이를 직접 더한다.
                    .safeAreaPadding(.bottom, style == .classic ? PopPangTabBarMetrics.height : 0)
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
        // 탭 화면의 여백은 위에서 더했으므로, 탭바는 레이아웃에 영향을 주지 않도록 overlay로 그린다.
        .overlay(alignment: .bottom) {
            if style == .classic {
                // overlay는 키보드 safe area 안에 놓여, 키보드가 올라오면 탭바도 키보드 위로 따라 올라간다.
                // 화면 전체 높이로 펼친 뒤 키보드 safe area를 무시해 탭바를 화면 바닥에 고정한다(키보드가 탭바를 덮는다).
                PopPangTabBar(tabs: tabs, selection: $selection, title: title, image: image, onReselect: reselect)
                    .frame(maxHeight: .infinity, alignment: .bottom)
                    .ignoresSafeArea(.keyboard, edges: .bottom)
            }
        }
        .environment(\.popPangTabBarStyle, style)
    }

    private func reselect(_ tab: Tab) {
        reselectCounts[tab, default: 0] += 1
    }
}

/// `UITabBar.configureAppearance()`가 만들던 기존 시스템 탭바와 같은 모양을 SwiftUI로 그린다.
public struct PopPangTabBar<Tab: Hashable>: View {
    @Binding private var selection: Tab
    private let tabs: [Tab]
    private let title: (Tab) -> String
    private let image: (Tab, _ isSelected: Bool) -> Image
    private let onReselect: ((Tab) -> Void)?
    /// 마지막으로 다른 탭으로 바꾼 시각. 다른 탭을 빠르게 두 번 누른 것을 다시 누름으로 보지 않는 데 쓴다.
    @State private var lastSelectionChange = Date.distantPast
    private static var reselectGuardInterval: TimeInterval { 0.5 }

    /// - Parameter onReselect: 이미 고른 탭을 다시 눌렀을 때 부른다.
    public init(
        tabs: [Tab],
        selection: Binding<Tab>,
        title: @escaping (Tab) -> String,
        image: @escaping (Tab, _ isSelected: Bool) -> Image,
        onReselect: ((Tab) -> Void)? = nil
    ) {
        self.tabs = tabs
        self._selection = selection
        self.title = title
        self.image = image
        self.onReselect = onReselect
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
            if selection == tab {
                // 다른 탭으로 바꾸자마자 한 번 더 누른 것(빠른 두 번 누르기)은 다시 누름으로 보지 않는다.
                guard Date().timeIntervalSince(lastSelectionChange) > Self.reselectGuardInterval else { return }
                onReselect?(tab)
            } else {
                selection = tab
                lastSelectionChange = Date()
            }
        } label: {
            // 기존 시스템 탭바처럼 아이콘을 에셋 원래 크기로 그리고, 중심 위치를 고정한다.
            // 고른 탭은 같은 아이콘의 모양만 쓰고 `PPColor.tabSelected`로 칠한다. 고르지 않은 탭은 에셋 원래 색(피그마 #9A9A9A)이다.
            // 높이가 0인 frame은 내용을 윗변에 중심 맞춰 두므로, offset이 곧 중심의 세로 위치가 된다.
            ZStack(alignment: .top) {
                image(tab, isSelected)
                    .renderingMode(isSelected ? .template : .original)
                    .foregroundStyle(PPColor.tabSelected)
                    .frame(height: 0)
                    .offset(x: PopPangTabBarMetrics.iconOffsetX, y: PopPangTabBarMetrics.iconCenterY)

                Text(title(tab))
                    .font(.scdream(isSelected ? .bold : .light, size: 10))
                    .foregroundStyle(isSelected ? PPColor.tabSelected : Color(uiColor: .gray))
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

private struct PopPangTabReselectCountKey: EnvironmentKey {
    static let defaultValue = 0
}

extension EnvironmentValues {
    /// 이 탭 화면의 탭을 이미 고른 상태에서 다시 누른 횟수.
    var popPangTabReselectCount: Int {
        get { self[PopPangTabReselectCountKey.self] }
        set { self[PopPangTabReselectCountKey.self] = newValue }
    }
}

public extension View {
    /// 이 화면이 들어 있는 탭을 이미 고른 상태에서 다시 누르면 `action`을 부른다.
    /// 목록이 있는 탭 화면이 맨 위로 올리는 데 쓴다. 쓰지 않는 화면은 아무 일도 하지 않는다.
    func onPopPangTabReselect(perform action: @escaping () -> Void) -> some View {
        modifier(PopPangTabReselectModifier(action: action))
    }
}

private struct PopPangTabReselectModifier: ViewModifier {
    @Environment(\.popPangTabReselectCount) private var count
    let action: () -> Void

    func body(content: Content) -> some View {
        // 탭 화면이 다시 만들어져 0으로 돌아가는 경우는 다시 누름이 아니다. 늘어날 때만 부른다.
        content.onChange(of: count) { oldValue, newValue in
            guard newValue > oldValue else { return }
            action()
        }
    }
}

public extension View {
    /// 스크롤 뷰 안의 첫 내용에 붙인다. 탭을 다시 누르면 스크롤 뷰가 이 위치(내용 맨 위)로 올라온다.
    /// 높이가 0인 표시를 overlay로 얹어서 레이아웃은 바뀌지 않는다. `scrollsToTopOnPopPangTabReselect()`와 함께 쓴다.
    func popPangTabReselectTopAnchor() -> some View {
        overlay(alignment: .top) {
            Color.clear
                .frame(height: 0)
                .id(PopPangTabReselectScroll.topID)
        }
    }

    /// `ScrollView`에 붙인다. 이 화면의 탭을 다시 누르면 `popPangTabReselectTopAnchor()`를 붙인 곳으로 올린다.
    func scrollsToTopOnPopPangTabReselect() -> some View {
        modifier(PopPangTabReselectScrollToTopModifier())
    }
}

private enum PopPangTabReselectScroll {
    static let topID = "popPangTabReselectTop"
}

private struct PopPangTabReselectScrollToTopModifier: ViewModifier {
    func body(content: Content) -> some View {
        ScrollViewReader { proxy in
            content
                .onPopPangTabReselect {
                    withAnimation {
                        proxy.scrollTo(PopPangTabReselectScroll.topID, anchor: .top)
                    }
                }
        }
    }
}
