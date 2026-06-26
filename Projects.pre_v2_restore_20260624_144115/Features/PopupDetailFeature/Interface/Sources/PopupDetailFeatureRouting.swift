import Domain

public enum PopupDetailFeatureRoute {
    case popupDetail(Popup)
    case reviewDetail([Review])
    case close
}

public protocol PopupDetailFeatureRouting: AnyObject {
    func route(to route: PopupDetailFeatureRoute)
}
