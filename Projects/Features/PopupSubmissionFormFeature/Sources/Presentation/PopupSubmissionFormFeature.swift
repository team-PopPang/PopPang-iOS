import ComposableArchitecture
import Domain
import Foundation

@Reducer
public struct PopupSubmissionFormFeature {
    @ObservableState
    public struct State: Equatable {
        public let mode: PopupSubmissionFormMode
        public var name: String
        public var startDate: Date
        public var endDate: Date
        public var roadAddress: String
        public var region: String
        public var descriptionText: String
        public var address: String
        public var openTime: String
        public var closeTime: String
        public var latitude: String
        public var longitude: String
        public var instaPostUrl: String
        public var instaPostId: String
        public var captionSummary: String
        public var caption: String
        public var geocodingQuery: String
        public var mediaType: Popup.MediaType
        public var isActive: Bool
        public var recommendList: [Recommend]
        public var selectedRecommendIds: [Int]
        public var imageItems: [PopupSubmissionImageItem]

        public init(
            mode: PopupSubmissionFormMode,
            name: String = "",
            startDate: Date = Date(),
            endDate: Date = Calendar.current.date(byAdding: .day, value: 7, to: Date()) ?? Date(),
            roadAddress: String = "",
            region: String = "",
            descriptionText: String = "",
            address: String = "",
            openTime: String = "",
            closeTime: String = "",
            latitude: String = "",
            longitude: String = "",
            instaPostUrl: String = "",
            instaPostId: String = "",
            captionSummary: String = "",
            caption: String = "",
            geocodingQuery: String = "",
            mediaType: Popup.MediaType = .image,
            isActive: Bool = true,
            recommendList: [Recommend] = [],
            selectedRecommendIds: [Int] = [],
            imageItems: [PopupSubmissionImageItem] = []
        ) {
            self.mode = mode
            self.name = name
            self.startDate = startDate
            self.endDate = endDate
            self.roadAddress = roadAddress
            self.region = region
            self.descriptionText = descriptionText
            self.address = address
            self.openTime = openTime
            self.closeTime = closeTime
            self.latitude = latitude
            self.longitude = longitude
            self.instaPostUrl = instaPostUrl
            self.instaPostId = instaPostId
            self.captionSummary = captionSummary
            self.caption = caption
            self.geocodingQuery = geocodingQuery
            self.mediaType = mediaType
            self.isActive = isActive
            self.recommendList = recommendList
            self.selectedRecommendIds = selectedRecommendIds
            self.imageItems = imageItems
        }
    }

    public enum Action: BindableAction, Equatable {
        case binding(BindingAction<State>)
        case recommendToggled(Int)
        case addImageRowTapped
        case removeImageRow(UUID)
        case imageURLChanged(UUID, String)
    }

    public init() {}

    public var body: some ReducerOf<Self> {
        BindingReducer()

        Reduce { state, action in
            switch action {
            case .binding(\.startDate):
                if state.endDate < state.startDate {
                    state.endDate = state.startDate
                }
                return .none

            case .binding:
                return .none

            case .recommendToggled(let id):
                if let index = state.selectedRecommendIds.firstIndex(of: id) {
                    state.selectedRecommendIds.remove(at: index)
                } else {
                    state.selectedRecommendIds.append(id)
                }
                return .none

            case .addImageRowTapped:
                state.imageItems.append(PopupSubmissionImageItem())
                return .none

            case .removeImageRow(let id):
                state.imageItems.removeAll { $0.id == id }
                return .none

            case let .imageURLChanged(id, text):
                guard let index = state.imageItems.firstIndex(where: { $0.id == id }) else {
                    return .none
                }
                state.imageItems[index].imageUrl = text
                return .none
            }
        }
    }
}
