import Foundation

public struct Popup: Hashable, Identifiable, Encodable, Sendable {
    public var id: String { popupUuid }

    public let popupUuid: String
    public let name: String
    public let startDate: Date
    public let endDate: Date
    public let openTime: String?
    public let closeTime: String?
    public let address: String
    public let roadAddress: String
    public let region: String
    public let latitude: Double?
    public let longitude: Double?
    public let instaPostId: String
    public let instaPostUrl: String
    public let captionSummary: String
    public let imageUrlList: [String]
    public let mediaType: MediaType
    public var favoriteCount: Int
    public var viewCount: Int
    public var isFavorited: Bool
    public let recommendList: [String]

    public init(
        popupUuid: String,
        name: String,
        startDate: Date,
        endDate: Date,
        openTime: String?,
        closeTime: String?,
        address: String,
        roadAddress: String,
        region: String,
        latitude: Double?,
        longitude: Double?,
        instaPostId: String,
        instaPostUrl: String,
        captionSummary: String,
        imageUrlList: [String],
        mediaType: MediaType,
        favoriteCount: Int,
        viewCount: Int,
        isFavorited: Bool,
        recommendList: [String]
    ) {
        self.popupUuid = popupUuid
        self.name = name
        self.startDate = startDate
        self.endDate = endDate
        self.openTime = openTime
        self.closeTime = closeTime
        self.address = address
        self.roadAddress = roadAddress
        self.region = region
        self.latitude = latitude
        self.longitude = longitude
        self.instaPostId = instaPostId
        self.instaPostUrl = instaPostUrl
        self.captionSummary = captionSummary
        self.imageUrlList = imageUrlList
        self.mediaType = mediaType
        self.favoriteCount = favoriteCount
        self.viewCount = viewCount
        self.isFavorited = isFavorited
        self.recommendList = recommendList
    }

    public enum MediaType: String, Codable, Sendable {
        case image = "IMAGE"
        case video = "VIDEO"
        case carousel = "CAROUSEL_ALBUM"
    }
}

public extension Popup {
    static let popupMock: Popup = {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd HH:mm"

        return Popup(
            popupUuid: "1234",
            name: "2025 짱구 부산 팝업스토어 팝업스토어 팝업스토어",
            startDate: formatter.date(from: "2025-10-13 11:00") ?? Date(),
            endDate: formatter.date(from: "2025-10-15 20:00") ?? Date(),
            openTime: "",
            closeTime: "",
            address: "테스트 주소",
            roadAddress: "부산 해운대구 우동 123-4",
            region: "부산",
            latitude: 1,
            longitude: 2,
            instaPostId: "5566778899",
            instaPostUrl: "https://instagram.com/p/shinchan2025",
            captionSummary: """
            짱구와 흰둥이, 철수, 훈이, 유리, 맹구까지 온 가족이 사랑하는 캐릭터들이 한자리에 모이는
            2025 짱구 부산 팝업스토어는 단순한 전시가 아니라 애니메이션 속 세계를 현실로 옮겨놓은 몰입형 체험 공간입니다.\n
            만화 속 명장면을 그대로 재현한 포토존, 짱구 가족의 집을 그대로 옮겨온 공간, 아이들과 부모 모두가 함께 즐길 수 있는
            체험형 이벤트가 풍성하게 준비되어 있으며, 부산 한정으로 제작된 특별 굿즈와 한정판 피규어, 생활 소품, 의류 컬렉션까지
            다양한 상품이 판매됩니다.\n
            특히 부산 바다를 모티브로 한 특별 일러스트 굿즈는 다른 지역에서는 만나볼 수 없는 희소성을 자랑합니다.\n
            웃음과 추억, 그리고 팬심을 동시에 충족시킬 이번 팝업스토어는 짱구 세대에게는 향수를, 새로운 세대에게는 즐거운 경험을 선사합니다.
            """,
            imageUrlList: [
                "https://poppang.co.kr/images/20251021-165057_18386722330126645/LH_메이커스_스튜디오_팝업스토어_소문내기_이벤트_1.jpg",
                "https://poppang.co.kr/images/20251021-165057_18386722330126645/LH_메이커스_스튜디오_팝업스토어_소문내기_이벤트_2.jpg",
            ],
            mediaType: .image,
            favoriteCount: 0,
            viewCount: 0,
            isFavorited: true,
            recommendList: ["테스트태그"]
        )
    }()

    static let popupMock2: Popup = {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd HH:mm"

        return Popup(
            popupUuid: "12345",
            name: "2025 짱구 부산 팝업스토어",
            startDate: formatter.date(from: "2025-10-13 11:00") ?? Date(),
            endDate: formatter.date(from: "2025-10-15 20:00") ?? Date(),
            openTime: "",
            closeTime: "",
            address: "테스트 주소",
            roadAddress: "부산 해운대구 우동 123-4",
            region: "부산",
            latitude: 1,
            longitude: 2,
            instaPostId: "5566778899",
            instaPostUrl: "https://instagram.com/p/shinchan2025",
            captionSummary: """
            짱구와 흰둥이, 철수, 훈이, 유리, 맹구까지 온 가족이 사랑하는 캐릭터들이 한자리에 모이는
            2025 짱구 부산 팝업스토어는 단순한 전시가 아니라 애니메이션 속 세계를 현실로 옮겨놓은 몰입형 체험 공간입니다.\n
            만화 속 명장면을 그대로 재현한 포토존, 짱구 가족의 집을 그대로 옮겨온 공간, 아이들과 부모 모두가 함께 즐길 수 있는
            체험형 이벤트가 풍성하게 준비되어 있으며, 부산 한정으로 제작된 특별 굿즈와 한정판 피규어, 생활 소품, 의류 컬렉션까지
            다양한 상품이 판매됩니다.\n
            특히 부산 바다를 모티브로 한 특별 일러스트 굿즈는 다른 지역에서는 만나볼 수 없는 희소성을 자랑합니다.\n
            웃음과 추억, 그리고 팬심을 동시에 충족시킬 이번 팝업스토어는 짱구 세대에게는 향수를, 새로운 세대에게는 즐거운 경험을 선사합니다.
            """,
            imageUrlList: [
                "https://poppang.co.kr/images/20251021-165057_18386722330126645/LH_메이커스_스튜디오_팝업스토어_소문내기_이벤트_1.jpg",
                "https://poppang.co.kr/images/20251021-165057_18386722330126645/LH_메이커스_스튜디오_팝업스토어_소문내기_이벤트_2.jpg",
            ],
            mediaType: .image,
            favoriteCount: 0,
            viewCount: 0,
            isFavorited: false,
            recommendList: ["테스트태그"]
        )
    }()
}

public struct User: Sendable {
    public let userUuid: String
    public let uid: String
    public let provider: String
    public let email: String?
    public var nickname: String?
    public let role: String
    public var isAlerted: Bool
    public var fcmToken: String?
    public var alertKeywordList: [String]?
    public var recommendList: [Int]?

    public init(
        userUuid: String,
        uid: String,
        provider: String,
        email: String?,
        nickname: String?,
        role: String,
        isAlerted: Bool,
        fcmToken: String?,
        alertKeywordList: [String]?,
        recommendList: [Int]?
    ) {
        self.userUuid = userUuid
        self.uid = uid
        self.provider = provider
        self.email = email
        self.nickname = nickname
        self.role = role
        self.isAlerted = isAlerted
        self.fcmToken = fcmToken
        self.alertKeywordList = alertKeywordList
        self.recommendList = recommendList
    }
}

public extension User {
    static let adminUser = User(
        userUuid: "4c3b9a55-f4ee-42cc-9bd2-82a5c811db13",
        uid: "67890",
        provider: "kakao",
        email: "john@example.com",
        nickname: "UI테스터",
        role: "admin",
        isAlerted: false,
        fcmToken: "",
        alertKeywordList: ["팝업스토어", "카페"],
        recommendList: [1, 2]
    )
}

public struct Keyword: Encodable, Equatable, Sendable {
    public let id: String
    public let keyword: String

    public init(keyword: String) {
        self.id = keyword
        self.keyword = keyword
    }
}

public struct RegionList: Identifiable, Hashable, Sendable {
    public var id: String { region }
    public let region: String
    public let districtList: [String]

    public init(region: String, districtList: [String]) {
        self.region = region
        self.districtList = districtList
    }
}

public struct Recommend: Identifiable, Equatable, Sendable {
    public let id: Int
    public let recommendName: String

    public init(id: Int, recommendName: String) {
        self.id = id
        self.recommendName = recommendName
    }
}
