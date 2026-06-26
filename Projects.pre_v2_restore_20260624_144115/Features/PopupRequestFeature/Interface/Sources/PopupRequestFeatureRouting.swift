public enum PopupRequestFeatureRoute {
    case close
}

public protocol PopupRequestFeatureRouting: AnyObject {
    func route(to route: PopupRequestFeatureRoute)
}
