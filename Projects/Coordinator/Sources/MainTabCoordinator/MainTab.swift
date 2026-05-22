import Foundation

public enum MainTab: Hashable, CaseIterable, Sendable {
    case home
    case calendar
    case map
    case favorites
    case profile

    var title: String {
        switch self {
        case .home:
            "홈"
        case .calendar:
            "캘린더"
        case .map:
            "팝팡지도"
        case .favorites:
            "팝팡"
        case .profile:
            "마이"
        }
    }

    var rawImageName: String {
        switch self {
        case .home:
            "home"
        case .calendar:
            "calendar"
        case .map:
            "map"
        case .favorites:
            "favorite"
        case .profile:
            "profile"
        }
    }

    func tabImage(selected: Bool) -> String {
        selected ? "\(rawImageName)_fill" : rawImageName
    }
}
