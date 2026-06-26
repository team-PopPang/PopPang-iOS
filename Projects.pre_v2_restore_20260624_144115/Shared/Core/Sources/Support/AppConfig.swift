import Foundation

public enum AppConfig {
    public static func string(
        forKey key: String,
        in infoDictionary: [String: Any]? = Bundle.main.infoDictionary
    ) -> String {
        guard let value = infoDictionary?[key] as? String else {
            preconditionFailure("Missing Info.plist value for key: \(key)")
        }
        return value
    }
}
