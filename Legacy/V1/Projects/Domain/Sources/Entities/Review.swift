import Foundation

public struct Review: Identifiable, Hashable, Sendable {
    public var id: UUID
    public let nickname: String
    public let info: String
    public let starCount: Int

    public init(
        id: UUID = UUID(),
        nickname: String,
        info: String,
        starCount: Int
    ) {
        self.id = id
        self.nickname = nickname
        self.info = info
        self.starCount = starCount
    }
}

public extension Review {
    static let mock: [Review] = [
        Review(
            nickname: "홍길동",
            info: "정말 재미있어요!정말 재미있어요!정말 재미있어요!정말 재미있어요!정말 재미있어요!정말 재미있어요!정말 재미있어요!",
            starCount: 5
        ),
        Review(nickname: "홍길동", info: "정말 재미있어요!", starCount: 4),
        Review(nickname: "홍길동", info: "정말 재미있어요!", starCount: 3),
        Review(nickname: "홍길동", info: "정말 재미있어요!", starCount: 5),
        Review(nickname: "홍길동", info: "정말 재미있어요!", starCount: 4),
        Review(
            nickname: "홍길동",
            info: "정말 재미있어요! 정말 재미있어요! 정말 재미있어요! 정말 재미있어요!",
            starCount: 3
        ),
    ]
}
