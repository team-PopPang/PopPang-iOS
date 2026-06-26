import Foundation

public enum PopupSubmissionFormValidationError: LocalizedError, Equatable {
    case message(String)

    public var errorDescription: String? {
        switch self {
        case .message(let message):
            return message
        }
    }
}

public enum PopupSubmissionFormValidator {
    public static func validateUser(
        _ state: PopupSubmissionFormFeature.State
    ) -> PopupSubmissionFormValidationError? {
        guard trimmed(state.name).isEmpty == false else { return .message("팝업명을 입력해 주세요.") }
        guard trimmed(state.roadAddress).isEmpty == false else { return .message("도로명 주소를 입력해 주세요.") }
        guard trimmed(state.region).isEmpty == false else { return .message("지역을 입력해 주세요.") }
        guard trimmed(state.descriptionText).isEmpty == false else { return .message("제보 내용을 입력해 주세요.") }
        guard state.selectedRecommendIds.isEmpty == false else { return .message("추천 카테고리를 1개 이상 선택해 주세요.") }
        guard state.endDate >= state.startDate else { return .message("종료일은 시작일보다 빠를 수 없습니다.") }
        guard validImageURLs(state).isEmpty == false else { return .message("이미지 URL을 1개 이상 입력해 주세요.") }
        guard validTimeField(state.openTime) else { return .message("오픈 시간을 HH:mm 형식으로 입력해 주세요.") }
        guard validTimeField(state.closeTime) else { return .message("마감 시간을 HH:mm 형식으로 입력해 주세요.") }
        guard validWebURLField(state.instaPostUrl) else { return .message("인스타그램 URL을 올바르게 입력해 주세요.") }
        return nil
    }

    public static func validateAdmin(
        _ state: PopupSubmissionFormFeature.State
    ) -> PopupSubmissionFormValidationError? {
        guard trimmed(state.name).isEmpty == false else { return .message("팝업명을 입력해 주세요.") }
        guard trimmed(state.roadAddress).isEmpty == false else { return .message("도로명 주소를 입력해 주세요.") }
        guard trimmed(state.region).isEmpty == false else { return .message("지역을 입력해 주세요.") }
        guard trimmed(state.address).isEmpty == false else { return .message("지번 주소를 입력해 주세요.") }
        guard trimmed(state.latitude).isEmpty == false else { return .message("위도를 입력해 주세요.") }
        guard trimmed(state.longitude).isEmpty == false else { return .message("경도를 입력해 주세요.") }
        guard Double(trimmed(state.latitude)) != nil else { return .message("위도를 숫자로 입력해 주세요.") }
        guard Double(trimmed(state.longitude)) != nil else { return .message("경도를 숫자로 입력해 주세요.") }
        guard trimmed(state.captionSummary).isEmpty == false else { return .message("한줄 소개를 입력해 주세요.") }
        guard trimmed(state.caption).isEmpty == false else { return .message("상세 소개를 입력해 주세요.") }
        guard state.selectedRecommendIds.isEmpty == false else { return .message("추천 카테고리를 1개 이상 선택해 주세요.") }
        guard state.endDate >= state.startDate else { return .message("종료일은 시작일보다 빠를 수 없습니다.") }
        guard validImageURLs(state).isEmpty == false else { return .message("이미지 URL을 1개 이상 입력해 주세요.") }
        guard validTimeField(state.openTime) else { return .message("오픈 시간을 HH:mm 형식으로 입력해 주세요.") }
        guard validTimeField(state.closeTime) else { return .message("마감 시간을 HH:mm 형식으로 입력해 주세요.") }
        guard validWebURLField(state.instaPostUrl) else { return .message("인스타그램 URL을 올바르게 입력해 주세요.") }
        return nil
    }

    static func trimmed(_ text: String) -> String {
        text.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    static func validImageURLs(_ state: PopupSubmissionFormFeature.State) -> [String] {
        state.imageItems
            .map { trimmed($0.imageUrl) }
            .filter { $0.isEmpty == false }
    }

    static func validTimeField(_ text: String) -> Bool {
        let trimmedValue = trimmed(text)
        return trimmedValue.isEmpty || PopupSubmissionTimeParser.parse(trimmedValue) != nil
    }

    static func validWebURLField(_ text: String) -> Bool {
        let trimmedValue = trimmed(text)
        guard trimmedValue.isEmpty == false else { return true }
        guard let url = URL(string: trimmedValue),
              let scheme = url.scheme?.lowercased()
        else { return false }
        return scheme == "http" || scheme == "https"
    }
}
