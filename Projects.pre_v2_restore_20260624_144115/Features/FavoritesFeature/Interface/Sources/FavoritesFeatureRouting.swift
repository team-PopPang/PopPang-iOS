import Domain

public enum FavoritesFeatureRoute {
    case alert
    case popupDetail(Popup)
    case selectHomeTab
}

public protocol FavoritesFeatureRouting: AnyObject {
    func route(to route: FavoritesFeatureRoute)
}
