import Domain

public enum AlertFeatureRoute {
    case popupDetail(Popup)
}

public protocol AlertFeatureRouting: AnyObject {
    func route(to route: AlertFeatureRoute)
}
