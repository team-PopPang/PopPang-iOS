public enum ProfileFeatureRoute {
    case alert
    case profileSetting(nickname: String, isAlerted: Bool)
    case notifications
    case serviceTerms
    case updateNickname(String)
    case logout
}

public protocol ProfileFeatureRouting: AnyObject {
    func route(to route: ProfileFeatureRoute)
}
