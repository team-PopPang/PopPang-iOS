import Domain
import Foundation

/// 내 정보 변경 실패를 화면에 보여 줄 문구로 바꾼다.
///
/// `UserError`가 아닌 실패는 다시 로그인해야 하는 경우라 `nil`을 돌려준다.
/// 다시 로그인해야 하면 앱이 로그인 화면으로 보내므로 따로 안내하지 않는다.
enum ProfileErrorMessage {
    static func nicknameCheck(for error: Error) -> String? {
        switch error as? UserError {
        case nil:
            return nil
        case .invalidNickname:
            return invalidNickname
        default:
            return String(localized: "닉네임을 확인하지 못했어요. 잠시 후 다시 시도해 주세요.", bundle: .module)
        }
    }

    /// 중복(409 4202)은 입력란 아래 중복 안내로 보여 주므로 `nil`이다.
    static func nicknameUpdate(for error: Error) -> String? {
        switch error as? UserError {
        case nil, .duplicateNickname:
            return nil
        case .invalidNickname:
            return invalidNickname
        case .failed:
            return String(localized: "닉네임을 바꾸지 못했어요. 잠시 후 다시 시도해 주세요.", bundle: .module)
        }
    }

    static func alertStatus(for error: Error) -> String? {
        guard error is UserError else { return nil }
        return String(localized: "알림 설정을 바꾸지 못했어요. 잠시 후 다시 시도해 주세요.", bundle: .module)
    }

    static func withdraw(for error: Error) -> String? {
        guard error is UserError else { return nil }
        return String(localized: "탈퇴하지 못했어요. 잠시 후 다시 시도해 주세요.", bundle: .module)
    }

    private static var invalidNickname: String {
        String(localized: "사용할 수 없는 닉네임이에요. 다른 닉네임을 입력해 주세요.", bundle: .module)
    }
}
