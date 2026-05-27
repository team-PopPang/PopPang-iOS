import Domain
import Foundation

public struct RegionListDTO: Decodable, Hashable, Sendable {
    public let region: String
    public let districtList: [String]

    public init(region: String, districtList: [String]) {
        self.region = region
        self.districtList = districtList
    }

    func toEntity() -> RegionList {
        RegionList(region: region, districtList: districtList)
    }
}
