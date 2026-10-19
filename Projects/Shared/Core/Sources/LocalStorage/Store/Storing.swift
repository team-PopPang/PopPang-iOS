import Foundation

/// 키로 값을 저장·조회·삭제하는 저장소 공통 protocol.
///
/// 저장소마다 더 필요한 기능은 그 저장소 타입의 `public extension`으로 추가한다.
/// Keychain은 문자열만 다루므로 이 protocol 대신 `KeychainStoring`을 쓴다.
public protocol Storing: Sendable {
    /// 저장된 값이 없거나 `T`로 꺼낼 수 없으면 `nil`이다.
    func value<T>(forKey key: String) -> T?
    func set<T>(_ value: T, forKey key: String) throws
    func removeValue(forKey key: String)
}
