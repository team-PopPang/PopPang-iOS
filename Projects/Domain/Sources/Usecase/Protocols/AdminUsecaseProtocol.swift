import Foundation

public protocol AdminUsecaseProtocol {
    /// 관리자 팝업 비활성화 V2. 관리자는 Access Token으로 정해진다.
    /// - Parameter popupUuid: 비활성화할 팝업 uuid
    func deactivatePopup(popupUuid: String) async throws

}
