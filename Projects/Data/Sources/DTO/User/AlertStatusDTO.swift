import Foundation

/// 알림 수신 설정 변경 응답 (명세 USER-05). 앱은 저장된 알림 상태만 읽는다.
public struct AlertStatusDTO: Decodable, Sendable {
    public let isAlerted: Bool
}
