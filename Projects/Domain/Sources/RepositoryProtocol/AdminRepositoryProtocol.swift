import Foundation

public protocol AdminRepositoryProtocol {
    /// 팝업스토어 제보 목록을 조회한다.
    ///
    /// Swagger:
    /// `GET /api/v1/admin/popup-submissions`
    ///
    /// 관리자 승인 대기(`PENDING`) 상태의 팝업스토어 제보 목록을 조회한다.
    /// 서버 응답 예시는 제보 id, 팝업명, 운영 시작일/종료일, 주소, 설명, 상태, 생성일을 포함한다.
    ///
    /// - Returns: 승인 대기 제보 목록.
    func getPopupSubmissionList() async throws -> [PopupSubmission]

    /// 팝업스토어 정보를 제보로 등록한다.
    ///
    /// Swagger:
    /// `POST /api/v1/admin/popup-submissions`
    ///
    /// 사용자가 입력한 팝업스토어 정보를 제보 목록에 등록한다.
    /// 서버 명세의 request body는 팝업명, 운영 시작일/종료일, 주소, 설명, 제출자 식별자를 포함한다.
    ///
    /// - Parameter request: 제보 등록 요청 값.
    func createPopupSubmission(_ request: PopupSubmissionCreateRequest) async throws

    /// 관리자 권한으로 특정 사용자의 팝업을 비활성화한다.
    ///
    /// Swagger:
    /// `PATCH /api/v1/admin/user/{userUuid}/popup/{popupUuid}/deactivate`
    ///
    /// `userUuid`가 관리자 권한을 가진 사용자일 때 특정 팝업의 `activated` 값을 `false`로 변경한다.
    /// 존재하지 않는 `userUuid` 또는 `popupUuid`를 요청하면 서버 오류 응답을 받을 수 있다.
    ///
    /// - Parameters:
    ///   - userUuid: 관리자 권한 검증에 사용할 사용자 uuid.
    ///   - popupUuid: 비활성화할 팝업 uuid.
    func deactivatePopupByUser(userUuid: String, popupUuid: String) async throws

    /// 관리자 권한으로 팝업을 비활성화한다.
    ///
    /// Swagger:
    /// `PATCH /api/v1/admin/popup/{popupUuid}/deactivate`
    ///
    /// 권장되는 V2 비활성화 API다.
    /// 인증/인가는 `Authorization` 헤더의 Bearer access token으로 처리되며,
    /// 관리자 권한이 있는 사용자만 접근할 수 있다.
    /// 대상 팝업의 `activated` 값을 `false`로 변경한다.
    ///
    /// - Parameter popupUuid: 비활성화할 팝업 uuid.
    func deactivatePopup(popupUuid: String) async throws

    /// 팝업스토어 제보 상태를 변경한다.
    ///
    /// Swagger:
    /// `PATCH /api/v1/admin/popup-submissions/{submissionId}/status`
    ///
    /// 제보 상태를 `PENDING`, `APPROVED`, `REJECTED` 중 하나로 변경한다.
    /// request body는 `popupSubmissionStatus` 필드를 사용한다.
    ///
    /// - Parameters:
    ///   - submissionId: 상태를 변경할 제보 id.
    ///   - status: 변경할 제보 상태.
    func updatePopupSubmissionStatus(submissionId: Int, status: PopupSubmissionStatus) async throws
}
