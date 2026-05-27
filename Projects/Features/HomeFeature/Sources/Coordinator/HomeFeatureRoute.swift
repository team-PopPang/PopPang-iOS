import Domain
import Foundation

public enum HomeFeatureRoute: Hashable, Sendable {
    case popupDetail(userUuid: String, popup: Popup)
    case comingPopupDetail(userUuid: String, popups: [Popup])
    case alert(userUuid: String)
    case reviewDetail([Review])
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
