import ComposableArchitecture
import Domain
import Foundation

@Reducer
public struct ReviewFeature {
    public enum Action: Equatable {
        case reviewWriteButtonTapped
        case reviewSheetPresented(Bool)
        case ratingSelected(Int)
        case reviewTextChanged(String)
        case submitReview
    }

    @ObservableState
    public struct State: Equatable {
        public var reviews: [Review]
        public var isPresentingReviewSheet = false
        public var rating = 0
        public var reviewText = ""

        public init(reviews: [Review] = Review.mock) {
            self.reviews = reviews
        }
    }

    public init() {}

    public var body: some ReducerOf<Self> {
        Reduce { state, action in
            switch action {
            case .reviewWriteButtonTapped:
                state.isPresentingReviewSheet = true
                return .none

            case .reviewSheetPresented(let isPresented):
                state.isPresentingReviewSheet = isPresented
                return .none

            case .ratingSelected(let rating):
                state.rating = rating
                return .none

            case .reviewTextChanged(let reviewText):
                state.reviewText = reviewText
                return .none

            case .submitReview:
                guard state.rating > 0 else { return .none }
                let reviewText = state.reviewText.trimmingCharacters(in: .whitespacesAndNewlines)
                guard reviewText.isEmpty == false else { return .none }

                let review = Review(
                    nickname: "나",
                    info: reviewText,
                    starCount: state.rating
                )
                state.reviews.insert(review, at: 0)
                state.rating = 0
                state.reviewText = ""
                state.isPresentingReviewSheet = false
                return .none
            }
        }
    }
}
