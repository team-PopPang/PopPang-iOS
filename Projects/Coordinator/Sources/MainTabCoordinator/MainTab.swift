import Foundation

public enum MainTab: Hashable, CaseIterable, Sendable {
    case home
    case map
    case favorites
    case profile

    var title: String {
        switch self {
        case .home:
            "홈"
        case .map:
            "지도"
        case .favorites:
            "찜"
        case .profile:
            "프로필"
        }
    }

    var systemImage: String {
        switch self {
        case .home:
            "house"
        case .map:
            "map"
        case .favorites:
            "heart"
        case .profile:
            "person"
        }
    }
}
