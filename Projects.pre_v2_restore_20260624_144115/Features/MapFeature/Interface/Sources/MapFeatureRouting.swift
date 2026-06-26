import Domain

public enum MapFeatureRoute {
    case popupDetail(Popup)
}

public protocol MapFeatureRouting: AnyObject {
    func route(to route: MapFeatureRoute)
}
