public protocol AdminRepositoryProtocol {
    /// 관리자 팝업 비활성화
    /// - Parameters:
    ///   - userUuid: userUuid
    ///   - popupUuid: popupUuid
    func deactivatePopup(userUuid: String, popupUuid: String) async throws
}
