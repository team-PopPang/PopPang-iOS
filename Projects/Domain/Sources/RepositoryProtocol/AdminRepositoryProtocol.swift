import Foundation

public protocol AdminRepositoryProtocol {
    /// 관리자 팝업 검증 내역 조회
    func getPopupValidationList() async throws -> Data

    /// 관리자 팝업 검증
    /// - Parameter parameters: API 요청 body
    func validatePopup(parameters: [String: Any]) async throws

    /// 관리자 팝업 등록
    /// - Parameter parameters: API 요청 body
    /// - Returns: 등록 응답에 포함된 popupUuid. 응답 body가 없으면 nil.
    func registerPopup(parameters: [String: Any]) async throws -> String?

    /// 팝업스토어 제보 등록
    /// - Parameter request: 제보 등록 요청
    func createPopupSubmission(_ request: PopupSubmissionCreateRequest) async throws

    /// 관리자 팝업 추천 정보 등록
    /// - Parameters:
    ///   - popupUuid: popupUuid
    ///   - recommendIds: 추천 id 목록
    func registerPopupRecommendations(popupUuid: String, recommendIds: [Int]) async throws

    /// 관리자 팝업 비활성화
    /// - Parameters:
    ///   - userUuid: userUuid
    ///   - popupUuid: popupUuid
    func deactivatePopup(userUuid: String, popupUuid: String) async throws
}
