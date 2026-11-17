import Domain
import Foundation

/// `GET /api/v2/recommend/map`의 항목. 카테고리와 지도 마커 색이다.
public struct RecommendMapDTO: Decodable, Sendable {
    public let id: Int
    public let recommendName: String
    public let color: String

    public init(id: Int, recommendName: String, color: String) {
        self.id = id
        self.recommendName = recommendName
        self.color = color
    }
}

public extension RecommendMapDTO {
    func toEntity() -> MapCategory {
        MapCategory(id: id, name: recommendName, colorHex: color)
    }
}
