import Foundation

public struct AdminPopupRegistrationResponseDTO: Decodable, Sendable {
    public let popupUuid: String?

    public init(popupUuid: String?) {
        self.popupUuid = popupUuid
    }

    public init(from decoder: Decoder) throws {
        if let singleValue = try? decoder.singleValueContainer(),
           let popupUuid = try? singleValue.decode(String.self) {
            self.popupUuid = popupUuid
            return
        }

        let container = try decoder.container(keyedBy: CodingKeys.self)

        if let popupUuid = Self.popupUuid(from: container) {
            self.popupUuid = popupUuid
            return
        }

        if let popupUuid = try? container.decodeIfPresent(String.self, forKey: .data) {
            self.popupUuid = popupUuid
            return
        }

        if let nested = try? container.nestedContainer(keyedBy: CodingKeys.self, forKey: .data),
           let popupUuid = Self.popupUuid(from: nested) {
            self.popupUuid = popupUuid
            return
        }

        if let nested = try? container.nestedContainer(keyedBy: CodingKeys.self, forKey: .popup),
           let popupUuid = Self.popupUuid(from: nested) {
            self.popupUuid = popupUuid
            return
        }

        self.popupUuid = nil
    }

    private enum CodingKeys: String, CodingKey {
        case popupUuid
        case uuid
        case id
        case data
        case popup
    }

    private static func popupUuid(from container: KeyedDecodingContainer<CodingKeys>) -> String? {
        stringValue(from: container, forKey: .popupUuid) ??
            stringValue(from: container, forKey: .uuid) ??
            stringValue(from: container, forKey: .id)
    }

    private static func stringValue(
        from container: KeyedDecodingContainer<CodingKeys>,
        forKey key: CodingKeys
    ) -> String? {
        if let value = try? container.decodeIfPresent(String.self, forKey: key) {
            return value
        }

        if let value = try? container.decodeIfPresent(Int.self, forKey: key) {
            return String(value)
        }

        return nil
    }
}
