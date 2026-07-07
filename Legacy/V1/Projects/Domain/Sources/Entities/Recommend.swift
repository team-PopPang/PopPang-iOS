public struct Recommend: Identifiable, Equatable, Sendable {
    public let id: Int
    public let recommendName: String

    public init(id: Int, recommendName: String) {
        self.id = id
        self.recommendName = recommendName
    }
}
