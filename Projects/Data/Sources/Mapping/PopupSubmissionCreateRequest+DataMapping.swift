import Domain
import Foundation

extension PopupSubmissionCreateRequest {
    func toDTO() -> PopupSubmissionCreateRequestDTO {
        PopupSubmissionCreateRequestDTO(
            userUuid: userUuid,
            name: name,
            startDate: popupSubmissionDateFormatter.string(from: startDate),
            endDate: popupSubmissionDateFormatter.string(from: endDate),
            openTime: openTime?.toDTO(),
            closeTime: closeTime?.toDTO(),
            address: address,
            roadAddress: roadAddress,
            region: region,
            instaPostUrl: instaPostUrl,
            description: description,
            imageList: imageList.map { $0.toDTO() },
            recommendIdList: recommendIdList
        )
    }
}

let popupSubmissionDateFormatter: DateFormatter = {
    let formatter = DateFormatter()
    formatter.locale = Locale(identifier: "ko_KR")
    formatter.dateFormat = "yyyy-MM-dd"
    return formatter
}()

extension DateFormatter {
    func dateStringToDate(_ text: String) throws -> Date {
        if let date = date(from: text) {
            return date
        }

        struct InvalidDateError: LocalizedError {
            let text: String

            var errorDescription: String? {
                "알 수 없는 팝업 제보 날짜 형식입니다: \(text)"
            }
        }

        throw InvalidDateError(text: text)
    }
}
