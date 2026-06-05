import Domain
import Foundation

enum PopupSubmissionMappingError: Error, Equatable, LocalizedError {
    case unknownStatus(String)

    var errorDescription: String? {
        switch self {
        case .unknownStatus(let status):
            "알 수 없는 팝업 제보 상태입니다: \(status)"
        }
    }
}

extension PopupSubmissionDTO {
    func toEntity() throws -> PopupSubmission {
        guard let status = PopupSubmissionStatus(rawValue: status) else {
            throw PopupSubmissionMappingError.unknownStatus(status)
        }

        PopupSubmission(
            id: id,
            name: name,
            startDate: startDate,
            endDate: endDate,
            address: address,
            description: description,
            status: status,
            createdAt: createdAt
        )
    }
}
