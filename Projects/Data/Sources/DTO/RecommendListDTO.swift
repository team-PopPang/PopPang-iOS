import Domain
import Foundation

public struct RecommendListDTO: Decodable, Identifiable, Sendable {
    public let id: Int
    public let recommendName: String

    public init(id: Int, recommendName: String) {
        self.id = id
        self.recommendName = recommendName
    }
}

public extension RecommendListDTO {
    func toModel() -> Recommend {
        Recommend(id: id, recommendName: recommendName)
    }
}
