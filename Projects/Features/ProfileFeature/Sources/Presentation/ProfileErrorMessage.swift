import Domain
import Foundation

/// 내 정보 변경 실패를 화면에 보여 줄 문구로 바꾼다.
enum ProfileErrorMessage {
    static func nicknameCheck(for error: Error) -> String {
        switch error as? UserError {
        case .invalidNickname:
            return invalidNickname
        default:
            return String(localized: "닉네임을 확인하지 못했어요. 잠시 후 다시 시도해 주세요.", bundle: .module)
        }
    }

    static func nicknameUpdate(for error: Error) -> String {
        switch error as? UserError {
        case .duplicateNickname:
            return String(localized: "이미 사용 중인 닉네임이에요. 다른 닉네임을 입력해 주세요.", bundle: .module)
        case .invalidNickname:
            return invalidNickname
        default:
            return String(localized: "닉네임을 바꾸지 못했어요. 잠시 후 다시 시도해 주세요.", bundle: .module)
        }
    }

    static var alertStatusFailed: String {
        String(localized: "알림 설정을 바꾸지 못했어요. 잠시 후 다시 시도해 주세요.", bundle: .module)
    }

    static var withdrawFailed: String {
        String(localized: "탈퇴하지 못했어요. 잠시 후 다시 시도해 주세요.", bundle: .module)
    }

    private static var invalidNickname: String {
        String(localized: "사용할 수 없는 닉네임이에요. 다른 닉네임을 입력해 주세요.", bundle: .module)
    }
}
