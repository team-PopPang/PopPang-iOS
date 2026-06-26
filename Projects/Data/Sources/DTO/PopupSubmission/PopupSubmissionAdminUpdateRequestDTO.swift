import Foundation

public struct PopupSubmissionAdminUpdateRequestDTO: Encodable, Sendable {
    public let status: String
    public let name: String?
    public let startDate: String?
    public let endDate: String?
    public let roadAddress: String?
    public let region: String?
    public let address: String?
    public let openTime: PopupSubmissionLocalTimeDTO?
    public let closeTime: PopupSubmissionLocalTimeDTO?
    public let latitude: Double?
    public let longitude: Double?
    public let captionSummary: String?
    public let caption: String?
    public let mediaType: String?
    public let instaPostUrl: String?
    public let instaPostId: String?
    public let geocodingQuery: String?
    public let imageList: [PopupSubmissionImageRequestDTO]
    public let recommendIdList: [Int]
    public let isActive: Bool?

    public init(
        status: String,
        name: String?,
        startDate: String?,
        endDate: String?,
        roadAddress: String?,
        region: String?,
        address: String?,
        openTime: PopupSubmissionLocalTimeDTO?,
        closeTime: PopupSubmissionLocalTimeDTO?,
        latitude: Double?,
        longitude: Double?,
        captionSummary: String?,
        caption: String?,
        mediaType: String?,
        instaPostUrl: String?,
        instaPostId: String?,
        geocodingQuery: String?,
        imageList: [PopupSubmissionImageRequestDTO],
        recommendIdList: [Int],
        isActive: Bool?
    ) {
        self.status = status
        self.name = name
        self.startDate = startDate
        self.endDate = endDate
        self.roadAddress = roadAddress
        self.region = region
        self.address = address
        self.openTime = openTime
        self.closeTime = closeTime
        self.latitude = latitude
        self.longitude = longitude
        self.captionSummary = captionSummary
        self.caption = caption
        self.mediaType = mediaType
        self.instaPostUrl = instaPostUrl
        self.instaPostId = instaPostId
        self.geocodingQuery = geocodingQuery
        self.imageList = imageList
        self.recommendIdList = recommendIdList
        self.isActive = isActive
    }

    enum CodingKeys: String, CodingKey {
        case status
        case name
        case startDate
        case endDate
        case roadAddress
        case region
        case address
        case openTime
        case closeTime
        case latitude
        case longitude
        case captionSummary
        case caption
        case mediaType
        case instaPostUrl
        case instaPostId
        case geocodingQuery
        case imageList
        case recommendIdList
        case isActive
        case activated
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(status, forKey: .status)
        try container.encodeIfPresent(name, forKey: .name)
        try container.encodeIfPresent(startDate, forKey: .startDate)
        try container.encodeIfPresent(endDate, forKey: .endDate)
        try container.encodeIfPresent(roadAddress, forKey: .roadAddress)
        try container.encodeIfPresent(region, forKey: .region)
        try container.encodeIfPresent(address, forKey: .address)
        try container.encodeIfPresent(openTime, forKey: .openTime)
        try container.encodeIfPresent(closeTime, forKey: .closeTime)
        try container.encodeIfPresent(latitude, forKey: .latitude)
        try container.encodeIfPresent(longitude, forKey: .longitude)
        try container.encodeIfPresent(captionSummary, forKey: .captionSummary)
        try container.encodeIfPresent(caption, forKey: .caption)
        try container.encodeIfPresent(mediaType, forKey: .mediaType)
        try container.encodeIfPresent(instaPostUrl, forKey: .instaPostUrl)
        try container.encodeIfPresent(instaPostId, forKey: .instaPostId)
        try container.encodeIfPresent(geocodingQuery, forKey: .geocodingQuery)
        try container.encode(imageList, forKey: .imageList)
        try container.encode(recommendIdList, forKey: .recommendIdList)
        try container.encodeIfPresent(isActive, forKey: .isActive)
        try container.encodeIfPresent(isActive, forKey: .activated)
    }
}
