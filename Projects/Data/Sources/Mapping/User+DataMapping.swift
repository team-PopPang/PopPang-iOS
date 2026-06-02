import Domain
import Foundation

extension Domain.User {
    func toDTO() -> UserDTO {
        UserDTO(
            userUuid: userUuid,
            uid: uid,
            provider: provider,
            email: email,
            nickname: nickname,
            role: role,
            isAlerted: isAlerted,
            fcmToken: fcmToken,
            alertKeywordList: alertKeywordList,
            recommendList: recommendList
        )
    }
}
