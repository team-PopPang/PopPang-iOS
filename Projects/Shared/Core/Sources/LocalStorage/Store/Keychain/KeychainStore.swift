import Foundation
import Security

public enum KeychainStoreError: Error, Equatable, Sendable {
    case unhandledStatus(OSStatus)
}

/// Keychain의 generic password 항목으로 문자열을 저장한다.
///
/// 이 기기가 처음 잠금 해제된 뒤부터 읽을 수 있고(백그라운드 요청에서도 토큰을 쓰기 위해서다),
/// 백업으로 다른 기기에 옮겨지지 않는다.
public struct KeychainStore: KeychainStoring {
    private let service: String

    public init(service: String = "com.poppang.auth") {
        self.service = service
    }

    /// 저장된 값이 없으면 `nil`이다. 잠금 상태 등으로 읽지 못하면 오류를 던진다.
    public func value(forKey key: String) throws -> String? {
        var query = baseQuery(forKey: key)
        query[kSecReturnData as String] = true
        query[kSecMatchLimit as String] = kSecMatchLimitOne

        var item: CFTypeRef?
        let status = SecItemCopyMatching(query as CFDictionary, &item)
        switch status {
        case errSecSuccess:
            guard let data = item as? Data else { return nil }
            return String(data: data, encoding: .utf8)

        case errSecItemNotFound:
            return nil

        default:
            throw KeychainStoreError.unhandledStatus(status)
        }
    }

    public func set(_ value: String, forKey key: String) throws {
        let data = Data(value.utf8)
        let updateStatus = SecItemUpdate(
            baseQuery(forKey: key) as CFDictionary,
            [kSecValueData as String: data] as CFDictionary
        )

        switch updateStatus {
        case errSecSuccess:
            return

        case errSecItemNotFound:
            var query = baseQuery(forKey: key)
            query[kSecValueData as String] = data
            query[kSecAttrAccessible as String] = kSecAttrAccessibleAfterFirstUnlockThisDeviceOnly
            let addStatus = SecItemAdd(query as CFDictionary, nil)
            guard addStatus == errSecSuccess else {
                throw KeychainStoreError.unhandledStatus(addStatus)
            }

        default:
            throw KeychainStoreError.unhandledStatus(updateStatus)
        }
    }

    public func removeValue(forKey key: String) {
        SecItemDelete(baseQuery(forKey: key) as CFDictionary)
    }
}

private extension KeychainStore {
    func baseQuery(forKey key: String) -> [String: Any] {
        [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: key,
        ]
    }
}
