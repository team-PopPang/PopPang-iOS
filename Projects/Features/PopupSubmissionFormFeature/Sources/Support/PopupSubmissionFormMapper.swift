import Domain
import Foundation

public enum PopupSubmissionFormMapper {
    public static func makeCreateRequest(
        from state: PopupSubmissionFormFeature.State,
        userUuid: String
    ) -> PopupSubmissionCreateRequest {
        PopupSubmissionCreateRequest(
            userUuid: userUuid,
            name: PopupSubmissionFormValidator.trimmed(state.name),
            startDate: state.startDate,
            endDate: state.endDate,
            openTime: PopupSubmissionTimeParser.parse(state.openTime),
            closeTime: PopupSubmissionTimeParser.parse(state.closeTime),
            address: PopupSubmissionFormValidator.trimmed(state.address).isEmpty
                ? PopupSubmissionFormValidator.trimmed(state.roadAddress)
                : PopupSubmissionFormValidator.trimmed(state.address),
            roadAddress: PopupSubmissionFormValidator.trimmed(state.roadAddress),
            region: PopupSubmissionFormValidator.trimmed(state.region),
            instaPostUrl: nilIfEmpty(PopupSubmissionFormValidator.trimmed(state.instaPostUrl)),
            description: PopupSubmissionFormValidator.trimmed(state.descriptionText),
            imageList: makeImageList(from: state),
            recommendIdList: state.selectedRecommendIds.sorted()
        )
    }

    public static func makeAdminUpdateRequest(
        from state: PopupSubmissionFormFeature.State,
        status: PopupSubmissionStatus
    ) -> PopupSubmissionAdminUpdateRequest {
        PopupSubmissionAdminUpdateRequest(
            status: status,
            name: nilIfEmpty(PopupSubmissionFormValidator.trimmed(state.name)),
            startDate: state.startDate,
            endDate: state.endDate,
            roadAddress: nilIfEmpty(PopupSubmissionFormValidator.trimmed(state.roadAddress)),
            region: nilIfEmpty(PopupSubmissionFormValidator.trimmed(state.region)),
            address: nilIfEmpty(PopupSubmissionFormValidator.trimmed(state.address)),
            openTime: PopupSubmissionTimeParser.parse(state.openTime),
            closeTime: PopupSubmissionTimeParser.parse(state.closeTime),
            latitude: Double(PopupSubmissionFormValidator.trimmed(state.latitude)),
            longitude: Double(PopupSubmissionFormValidator.trimmed(state.longitude)),
            captionSummary: nilIfEmpty(PopupSubmissionFormValidator.trimmed(state.captionSummary)),
            caption: nilIfEmpty(PopupSubmissionFormValidator.trimmed(state.caption)),
            mediaType: state.mediaType,
            instaPostUrl: nilIfEmpty(PopupSubmissionFormValidator.trimmed(state.instaPostUrl)),
            instaPostId: nilIfEmpty(PopupSubmissionFormValidator.trimmed(state.instaPostId)),
            geocodingQuery: nilIfEmpty(PopupSubmissionFormValidator.trimmed(state.geocodingQuery)),
            imageList: makeImageList(from: state),
            recommendIdList: state.selectedRecommendIds.sorted(),
            isActive: state.isActive
        )
    }

    public static func makeAdminFormState(from detail: PopupSubmissionDetail) -> PopupSubmissionFormFeature.State {
        PopupSubmissionFormFeature.State(
            mode: .adminReview,
            name: detail.name,
            startDate: detail.startDate,
            endDate: detail.endDate,
            roadAddress: detail.roadAddress,
            region: detail.region,
            address: detail.address ?? "",
            openTime: PopupSubmissionTimeParser.string(from: detail.openTime),
            closeTime: PopupSubmissionTimeParser.string(from: detail.closeTime),
            instaPostUrl: detail.instaPostUrl ?? "",
            recommendList: detail.recommendList,
            selectedRecommendIds: detail.recommendIdList,
            imageItems: detail.imageList
                .sorted { $0.sortOrder < $1.sortOrder }
                .map { PopupSubmissionImageItem(imageUrl: $0.imageUrl) }
        )
    }

    private static func makeImageList(from state: PopupSubmissionFormFeature.State) -> [PopupSubmissionImage] {
        PopupSubmissionFormValidator.validImageURLs(state).enumerated().map { index, imageURL in
            PopupSubmissionImage(imageUrl: imageURL, sortOrder: index)
        }
    }

    private static func nilIfEmpty(_ text: String) -> String? {
        text.isEmpty ? nil : text
    }
}
