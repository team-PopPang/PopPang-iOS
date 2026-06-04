import Domain
import Foundation

public enum HomeFeatureRoute: Sendable {
    case popupDetail(userUuid: String, popup: Popup)
    case comingPopupDetail(userUuid: String, popups: [Popup])
    case alert(userUuid: String)
    case reviewDetail([Review])
    case popupReport(userUuid: String)
}

extension HomeFeatureRoute: Hashable {
    public static func == (lhs: HomeFeatureRoute, rhs: HomeFeatureRoute) -> Bool {
        switch (lhs, rhs) {
        case let (.popupDetail(lhsUserUuid, lhsPopup), .popupDetail(rhsUserUuid, rhsPopup)):
            lhsUserUuid == rhsUserUuid && lhsPopup.popupUuid == rhsPopup.popupUuid
        case let (.comingPopupDetail(lhsUserUuid, lhsPopups), .comingPopupDetail(rhsUserUuid, rhsPopups)):
            lhsUserUuid == rhsUserUuid && lhsPopups.map(\.popupUuid) == rhsPopups.map(\.popupUuid)
        case let (.alert(lhsUserUuid), .alert(rhsUserUuid)):
            lhsUserUuid == rhsUserUuid
        case let (.reviewDetail(lhsReviews), .reviewDetail(rhsReviews)):
            lhsReviews.map(\.id) == rhsReviews.map(\.id)
        case let (.popupReport(lhsUserUuid), .popupReport(rhsUserUuid)):
            lhsUserUuid == rhsUserUuid
        default:
            false
        }
    }

    public func hash(into hasher: inout Hasher) {
        switch self {
        case let .popupDetail(userUuid, popup):
            hasher.combine("popupDetail")
            hasher.combine(userUuid)
            hasher.combine(popup.popupUuid)
        case let .comingPopupDetail(userUuid, popups):
            hasher.combine("comingPopupDetail")
            hasher.combine(userUuid)
            hasher.combine(popups.map(\.popupUuid))
        case let .alert(userUuid):
            hasher.combine("alert")
            hasher.combine(userUuid)
        case let .reviewDetail(reviews):
            hasher.combine("reviewDetail")
            hasher.combine(reviews.map(\.id))
        case let .popupReport(userUuid):
            hasher.combine("popupReport")
            hasher.combine(userUuid)
        }
    }
}

public enum HomeSheetRoute: Identifiable, Hashable, Sendable {
    case regionSheet
    case sortSheet

    public var id: String {
        switch self {
        case .regionSheet:
            "regionSheet"
        case .sortSheet:
            "sortSheet"
        }
    }
}

public enum HomeFullScreenRoute: Identifiable, Hashable, Sendable {
    case search(uuid: String)

    public var id: String {
        switch self {
        case .search(let uuid):
            "search-\(uuid)"
        }
    }
}
