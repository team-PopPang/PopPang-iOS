import Foundation

public enum NicknameValidationState {
    case none
    case success
    case duplicate
    case invalidSpace
    case checking
    case tooShort
}
