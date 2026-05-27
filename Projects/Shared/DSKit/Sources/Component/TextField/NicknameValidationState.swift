import Foundation

public enum NicknameValidationState: Equatable, Sendable {
    case none
    case success
    case duplicate
    case invalidSpace
    case checking
    case tooShort
}
