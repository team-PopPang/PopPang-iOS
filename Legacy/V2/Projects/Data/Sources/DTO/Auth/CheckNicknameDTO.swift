import Foundation

public struct CheckNicknameDTO: Decodable, Sendable {
    public let isDuplicated: Bool

    public init(isDuplicated: Bool) {
        self.isDuplicated = isDuplicated
    }
}
