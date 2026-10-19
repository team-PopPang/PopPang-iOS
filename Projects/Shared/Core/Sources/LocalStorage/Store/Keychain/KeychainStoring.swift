import Foundation

/// 토큰처럼 Keychain에만 둘 문자열을 다룬다.
public protocol KeychainStoring: Sendable {
    /// 저장된 값이 없으면 `nil`이다. 저장소를 읽지 못하면(기기 잠금 등) 오류를 던진다.
    func value(forKey key: String) throws -> String?
    func set(_ value: String, forKey key: String) throws
    func removeValue(forKey key: String)
}
