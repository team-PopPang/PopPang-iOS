import Compound
import Domain
import Foundation

@Compound
final class ReviewFeatureCompound {
    enum Action {
        case reviewWriteButtonTapped
        case reviewSheetPresented(Bool)
        case ratingSelected(Int)
        case reviewTextChanged(String)
        case submitReview
    }

    enum Reaction {
        case setReviews([Review])
        case setReviewSheetPresented(Bool)
        case setRating(Int)
        case setReviewText(String)
    }

    struct State: Equatable {
        var reviews: [Review]
        var isPresentingReviewSheet = false
        var rating = 0
        var reviewText = ""
    }

    var state: State

    init(reviews: [Review] = Review.mock) {
        self.state = State(reviews: reviews)
    }

    func react(action: Action) -> AsyncStream<Reaction> {
        switch action {
        case .reviewWriteButtonTapped:
            return .just(.setReviewSheetPresented(true))

        case .reviewSheetPresented(let isPresented):
            return .just(.setReviewSheetPresented(isPresented))

        case .ratingSelected(let rating):
            return .just(.setRating(rating))

        case .reviewTextChanged(let reviewText):
            return .just(.setReviewText(reviewText))

        case .submitReview:
            guard state.rating > 0 else { return emptyReactionStream() }
            let reviewText = state.reviewText.trimmingCharacters(in: .whitespacesAndNewlines)
            guard reviewText.isEmpty == false else { return emptyReactionStream() }

            let review = Review(
                nickname: "나",
                info: reviewText,
                starCount: state.rating
            )

            return .concat(
                .just(.setReviews([review] + state.reviews)),
                .just(.setRating(0)),
                .just(.setReviewText("")),
                .just(.setReviewSheetPresented(false))
            )
        }
    }

    func reduce(state: State, reaction: Reaction) -> State {
        var newState = state

        switch reaction {
        case .setReviews(let reviews):
            newState.reviews = reviews
        case .setReviewSheetPresented(let isPresented):
            newState.isPresentingReviewSheet = isPresented
        case .setRating(let rating):
            newState.rating = rating
        case .setReviewText(let reviewText):
            newState.reviewText = reviewText
        }

        return newState
    }

    private func emptyReactionStream() -> AsyncStream<Reaction> {
        AsyncStream { continuation in
            continuation.finish()
        }
    }
}
