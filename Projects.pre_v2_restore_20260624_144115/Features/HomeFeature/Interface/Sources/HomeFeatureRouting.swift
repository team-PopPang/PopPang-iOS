import Domain

public enum HomeFeatureRoute {
    case popupDetail(Popup)
    case alert
    case search
    case comingPopupDetail([Popup])
    case popupRequest
    case popupRequestManagement
}

public protocol HomeFeatureRouting: AnyObject {
    func route(to route: HomeFeatureRoute)
}
