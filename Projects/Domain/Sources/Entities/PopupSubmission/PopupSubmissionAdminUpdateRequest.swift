import Foundation

public struct PopupSubmissionAdminUpdateRequest: Equatable, Sendable {
    public let status: PopupSubmissionStatus
    public let name: String?
    public let startDate: Date?
    public let endDate: Date?
    public let roadAddress: String?
    public let region: String?
    public let address: String?
    public let openTime: PopupSubmissionLocalTime?
    public let closeTime: PopupSubmissionLocalTime?
    public let latitude: Double?
    public let longitude: Double?
    public let captionSummary: String?
    public let caption: String?
    public let mediaType: Popup.MediaType?
    public let instaPostUrl: String?
    public let instaPostId: String?
    public let geocodingQuery: String?
    public let imageList: [PopupSubmissionImage]
    public let recommendIdList: [Int]
    public let isActive: Bool?

    public init(
        status: PopupSubmissionStatus,
        name: String? = nil,
        startDate: Date? = nil,
        endDate: Date? = nil,
        roadAddress: String? = nil,
        region: String? = nil,
        address: String? = nil,
        openTime: PopupSubmissionLocalTime? = nil,
        closeTime: PopupSubmissionLocalTime? = nil,
        latitude: Double? = nil,
        longitude: Double? = nil,
        captionSummary: String? = nil,
        caption: String? = nil,
        mediaType: Popup.MediaType? = nil,
        instaPostUrl: String? = nil,
        instaPostId: String? = nil,
        geocodingQuery: String? = nil,
        imageList: [PopupSubmissionImage] = [],
        recommendIdList: [Int] = [],
        isActive: Bool? = nil
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
}
