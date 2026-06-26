import Foundation

public struct PopupSubmissionDetail: Identifiable, Equatable, Sendable {
    public let id: Int
    public let name: String
    public let startDate: Date
    public let endDate: Date
    public let roadAddress: String
    public let region: String
    public let description: String
    public let recommendIdList: [Int]
    public let recommendList: [Recommend]
    public let imageList: [PopupSubmissionImage]
    public let address: String?
    public let openTime: PopupSubmissionLocalTime?
    public let closeTime: PopupSubmissionLocalTime?
    public let instaPostUrl: String?
    public let status: PopupSubmissionStatus

    public init(
        id: Int,
        name: String,
        startDate: Date,
        endDate: Date,
        roadAddress: String,
        region: String,
        description: String,
        recommendIdList: [Int],
        recommendList: [Recommend],
        imageList: [PopupSubmissionImage],
        address: String?,
        openTime: PopupSubmissionLocalTime?,
        closeTime: PopupSubmissionLocalTime?,
        instaPostUrl: String?,
        status: PopupSubmissionStatus
    ) {
        self.id = id
        self.name = name
        self.startDate = startDate
        self.endDate = endDate
        self.roadAddress = roadAddress
        self.region = region
        self.description = description
        self.recommendIdList = recommendIdList
        self.recommendList = recommendList
        self.imageList = imageList
        self.address = address
        self.openTime = openTime
        self.closeTime = closeTime
        self.instaPostUrl = instaPostUrl
        self.status = status
    }
}
