import Domain
import Foundation

public struct KeywordDTO: Decodable, Identifiable, Sendable {
    public var id: String { keyword }
    public let keyword: String

    enum CodingKeys: String, CodingKey {
        case keyword = "alertKeyword"
    }

    public init(keyword: String) {
        self.keyword = keyword
    }
}

public extension KeywordDTO {
    func toModel() -> Keyword {
        Keyword(keyword: keyword)
    }
}
