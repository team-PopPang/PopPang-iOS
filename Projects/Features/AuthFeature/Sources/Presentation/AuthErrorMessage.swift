import Domain
import Foundation

/// 로그인·가입 실패를 화면에 보여 줄 문구로 바꾼다.
enum AuthErrorMessage {
    /// - Returns: 사용자가 로그인 창을 닫았으면 `nil`
    static func login(for error: Error) -> String? {
        switch error as? AuthError {
        case .cancelled:
            return nil
        case .inactiveAccount:
            return String(localized: "탈퇴한 계정이에요. 다른 계정으로 로그인해 주세요.", bundle: .module)
        case .socialAccountConflict:
            return String(localized: "이미 다른 방법으로 가입된 계정이에요. 처음 가입한 방법으로 로그인해 주세요.", bundle: .module)
        default:
            return String(localized: "로그인하지 못했어요. 잠시 후 다시 시도해 주세요.", bundle: .module)
        }
    }

    static func signup(for error: Error) -> String {
        switch error as? AuthError {
        case .duplicateNickname:
            return String(localized: "이미 사용 중인 닉네임이에요. 다른 닉네임을 입력해 주세요.", bundle: .module)
        case .invalidSignupRequest:
            return String(localized: "입력한 정보를 다시 확인해 주세요.", bundle: .module)
        case .inactiveAccount:
            return String(localized: "탈퇴한 계정이에요. 다른 계정으로 로그인해 주세요.", bundle: .module)
        default:
            return String(localized: "가입하지 못했어요. 잠시 후 다시 시도해 주세요.", bundle: .module)
        }
    }

    static var recommendListLoadFailed: String {
        String(localized: "관심 카테고리를 불러오지 못했어요. 잠시 후 다시 시도해 주세요.", bundle: .module)
    }

    static var nicknameCheckFailed: String {
        String(localized: "닉네임을 확인하지 못했어요. 잠시 후 다시 시도해 주세요.", bundle: .module)
    }

    static var signupSessionExpired: String {
        String(localized: "가입 시간이 지났어요. 다시 로그인해 주세요.", bundle: .module)
    }
}
