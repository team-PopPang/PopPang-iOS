import Foundation

public protocol AdminRepositoryProtocol {
    /// 관리자 권한으로 팝업을 비활성화한다.
    ///
    /// `PATCH /api/v2/admin/popup/{popupUuid}/deactivate`
    ///
    /// Access Token의 사용자가 관리자일 때만 처리된다.
    /// 대상 팝업의 `activated` 값을 `false`로 변경한다. 실패하면 `PopupError`를 던진다.
    ///
    /// - Parameter popupUuid: 비활성화할 팝업 uuid.
    func deactivatePopup(popupUuid: String) async throws

}
