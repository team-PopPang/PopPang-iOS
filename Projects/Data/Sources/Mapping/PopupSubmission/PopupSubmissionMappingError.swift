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
