import Domain

public enum CalendarFeatureRoute {
    case alert
    case popupDetail(Popup)
}

public protocol CalendarFeatureRouting: AnyObject {
    func route(to route: CalendarFeatureRoute)
}
