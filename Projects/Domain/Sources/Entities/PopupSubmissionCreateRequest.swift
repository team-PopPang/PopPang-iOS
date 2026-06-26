import Foundation

public struct PopupSubmissionCreateRequest: Equatable, Sendable {
    public let userUuid: String
    public let name: String
    public let startDate: Date
    public let endDate: Date
    public let openTime: PopupSubmissionLocalTime?
    public let closeTime: PopupSubmissionLocalTime?
    public let address: String
    public let roadAddress: String
    public let region: String
    public let instaPostUrl: String?
    public let description: String
    public let imageList: [PopupSubmissionImage]
    public let recommendIdList: [Int]

    public init(
        userUuid: String,
        name: String,
        startDate: Date,
        endDate: Date,
        openTime: PopupSubmissionLocalTime? = nil,
        closeTime: PopupSubmissionLocalTime? = nil,
        address: String,
        roadAddress: String,
        region: String,
        instaPostUrl: String? = nil,
        description: String,
        imageList: [PopupSubmissionImage] = [],
        recommendIdList: [Int] = []
    ) {
        self.userUuid = userUuid
        self.name = name
        self.startDate = startDate
        self.endDate = endDate
        self.openTime = openTime
        self.closeTime = closeTime
        self.address = address
        self.roadAddress = roadAddress
        self.region = region
        self.instaPostUrl = instaPostUrl
        self.description = description
        self.imageList = imageList
        self.recommendIdList = recommendIdList
    }
}
