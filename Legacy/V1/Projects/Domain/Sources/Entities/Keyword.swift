public struct Keyword: Encodable, Equatable, Sendable {
    public let id: String
    public let keyword: String

    public init(keyword: String) {
        self.id = keyword
        self.keyword = keyword
    }
}
