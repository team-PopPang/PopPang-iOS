import DSKit
import SwiftUI

/// 앱 메인 탭과 같은 5개 탭으로 시스템 탭바와 `PopPangTabBar`(기존 모양)를 바꿔 보며 비교한다.
/// 실행 인자 `-tabBarStyle system` 또는 `-tabBarStyle classic`으로 시작 스타일을 고를 수 있다.
struct TabBarDemoView: View {
    @State private var style: PopPangTabBarStyle = Self.launchStyle
    @State private var selection: DemoTab = .home

    var body: some View {
        PopPangTabView(
            selection: $selection,
            tabs: DemoTab.allCases,
            style: style,
            title: \.title,
            image: { tab, isSelected in
                DSKitResource.image(tab.imageName(selected: isSelected))
            }
        ) { tab in
            Group {
                if tab == .home {
                    DSKitCatalogView()
                } else {
                    DemoTabContent(tab: tab)
                }
            }
            .safeAreaInset(edge: .top, spacing: 0) {
                stylePicker
            }
        }
        .id(style)
    }

    private var stylePicker: some View {
        Picker("탭바 스타일", selection: $style) {
            Text("시스템").tag(PopPangTabBarStyle.system)
            Text("기존(커스텀)").tag(PopPangTabBarStyle.classic)
        }
        .pickerStyle(.segmented)
        .padding(.horizontal, .contentPadding)
        .padding(.vertical, 8)
        .background(Color.mainGray4)
    }

    private static var launchStyle: PopPangTabBarStyle {
        UserDefaults.standard.string(forKey: "tabBarStyle") == "system" ? .system : .classic
    }
}

/// 앱의 `MainTab`과 같은 제목과 아이콘을 쓴다.
private enum DemoTab: Hashable, CaseIterable {
    case home
    case calendar
    case map
    case favorites
    case profile

    var title: String {
        switch self {
        case .home: "홈"
        case .calendar: "캘린더"
        case .map: "팝팡지도"
        case .favorites: "팝팡"
        case .profile: "마이"
        }
    }

    func imageName(selected: Bool) -> String {
        let name = switch self {
        case .home: "home"
        case .calendar: "calendar"
        case .map: "map"
        case .favorites: "favorite"
        case .profile: "profile"
        }
        return selected ? "\(name)_fill" : name
    }
}

/// 탭바 아래로 콘텐츠가 가려지지 않는지, 키보드가 올라올 때 탭바가 어떻게 되는지 확인하는 화면.
private struct DemoTabContent: View {
    let tab: DemoTab
    @State private var text = ""

    var body: some View {
        List {
            Section {
                TextField("키보드 확인용 입력", text: $text)
            }
            Section("\(tab.title) 탭") {
                ForEach(1...30, id: \.self) { index in
                    Text("행 \(index)")
                }
            }
        }
    }
}
