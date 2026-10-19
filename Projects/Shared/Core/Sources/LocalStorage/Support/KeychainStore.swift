import Foundation
import Security

public enum KeychainStoreError: Error, Equatable, Sendable {
    case unhandledStatus(OSStatus)
}

/// Keychain의 generic password 항목으로 문자열을 저장한다.
///
/// 이 기기가 처음 잠금 해제된 뒤부터 읽을 수 있고(백그라운드 요청에서도 토큰을 쓰기 위해서다),
/// 백업으로 다른 기기에 옮겨지지 않는다.
public struct KeychainStore: SecureStoring {
    private let service: String

    public init(service: String = "com.poppang.auth") {
        self.service = service
    }

    public func string(forKey key: String) -> String? {
        var query = baseQuery(forKey: key)
        query[kSecReturnData as String] = true
        query[kSecMatchLimit as String] = kSecMatchLimitOne

        var item: CFTypeRef?
        guard SecItemCopyMatching(query as CFDictionary, &item) == errSecSuccess,
              let data = item as? Data
        else {
            return nil
        }
        return String(data: data, encoding: .utf8)
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
