import Foundation

public protocol AdminUsecaseProtocol {
    /// 관리자 팝업 제보 목록 조회
    func getPopupSubmissionList() async throws -> [PopupSubmission]

    /// 팝업스토어 제보 등록
    /// - Parameter request: 제보 등록 요청
    func createPopupSubmission(_ request: PopupSubmissionCreateRequest) async throws

    /// 관리자 팝업 비활성화
    /// - Parameters:
    ///   - userUuid: userUuid
    ///   - popupUuid: popupUuid
    @available(*, deprecated, message: "deactivatePopup(popupUuid:)를 사용하세요.")
    func deactivatePopupByUser(userUuid: String, popupUuid: String) async throws

    /// 관리자 팝업 비활성화 V2. 관리자는 Access Token으로 정해진다.
    /// - Parameter popupUuid: 비활성화할 팝업 uuid
    func deactivatePopup(popupUuid: String) async throws

    /// 팝업스토어 제보 상태 변경
    /// - Parameters:
    ///   - submissionId: 제보 id
    ///   - status: 변경할 제보 상태
    func updatePopupSubmissionStatus(submissionId: Int, status: PopupSubmissionStatus) async throws
}
