public enum PopupRequestManagementFeatureRoute {
    case detail(String)
    case back
}

public protocol PopupRequestManagementFeatureRouting: AnyObject {
    func route(to route: PopupRequestManagementFeatureRoute)
}
