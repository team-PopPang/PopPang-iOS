import Domain

public enum SearchFeatureRoute {
    case selectPopup(Popup)
    case close
}

public protocol SearchFeatureRouting: AnyObject {
    func route(to route: SearchFeatureRoute)
}
