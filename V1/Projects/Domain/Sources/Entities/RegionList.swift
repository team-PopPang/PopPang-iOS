public struct RegionList: Identifiable, Hashable, Sendable {
    public var id: String { region }
    public let region: String
    public let districtList: [String]

    public init(region: String, districtList: [String]) {
        self.region = region
        self.districtList = districtList
    }
}
