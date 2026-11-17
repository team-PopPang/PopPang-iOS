/// 지도에서 쓰는 팝업 카테고리. 필터 칩과 마커 색에 쓴다.
public struct MapCategory: Identifiable, Equatable, Hashable, Sendable {
    public let id: Int
    public let name: String
    /// 마커 색. 서버가 주는 대문자 `#RRGGBB` 문자열이다.
    public let colorHex: String

    public init(id: Int, name: String, colorHex: String) {
        self.id = id
        self.name = name
        self.colorHex = colorHex
    }
}
