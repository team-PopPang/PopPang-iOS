import Foundation

/// 알림 수신 설정 변경 응답 (명세 USER-05)
public struct AlertStatusDTO: Decodable, Sendable {
    public let userUuid: String
    public let isAlerted: Bool
}
