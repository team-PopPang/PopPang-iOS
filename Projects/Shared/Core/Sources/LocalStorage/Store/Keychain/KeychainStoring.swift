import Foundation

/// 토큰처럼 Keychain에만 둘 문자열을 다룬다.
public protocol KeychainStoring: Sendable {
    func value(forKey key: String) -> String?
    func set(_ value: String, forKey key: String) throws
    func removeValue(forKey key: String)
}
