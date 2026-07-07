import Foundation

public protocol KeyValueStoring: Sendable {
    func object(forKey key: String) -> Any?
    func set(_ value: Any?, forKey key: String)
    func removeObject(forKey key: String)
}
