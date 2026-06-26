import Domain
import SwiftUI

public struct ReviewFeatureView: View {
    private let reviews: [Review]

    public init(reviews: [Review] = Review.mock) {
        self.reviews = reviews
    }

    public var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                Text("ReviewFeature")
                    .font(.title.bold())
                Text("리뷰 화면은 임시 placeholder 상태입니다.")
                    .foregroundStyle(.secondary)
                ReviewPreviewSection(reviews: reviews, onShowAllReviews: {})
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(24)
        }
    }
}

public struct ReviewPreviewSection: View {
    let reviews: [Review]
    let onShowAllReviews: () -> Void

    public init(
        reviews: [Review] = Review.mock,
        onShowAllReviews: @escaping () -> Void
    ) {
        self.reviews = reviews
        self.onShowAllReviews = onShowAllReviews
    }

    public var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("리뷰 \(reviews.count)개")
                    .font(.headline)
                Spacer()
                Button("전체 보기") {
                    onShowAllReviews()
                }
            }
            ForEach(reviews.prefix(3)) { review in
                ReviewCell(
                    nickname: review.nickname,
                    review: review.info,
                    starCount: review.starCount
                )
            }
        }
    }
}

public struct ReviewCell: View {
    let nickname: String
    let review: String
    let starCount: Int

    public init(
        nickname: String,
        review: String,
        starCount: Int
    ) {
        self.nickname = nickname
        self.review = review
        self.starCount = starCount
    }

    public var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(nickname)
                .font(.headline)
            Text(String(repeating: "★", count: max(starCount, 0)))
                .foregroundStyle(.orange)
            Text(review)
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(16)
        .background(Color(.secondarySystemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}

public struct ReviewWriteSheet: View {
    @Binding var rating: Int
    @Binding var reviewText: String
    let onSubmit: () -> Void

    public init(
        rating: Binding<Int>,
        reviewText: Binding<String>,
        onSubmit: @escaping () -> Void
    ) {
        self._rating = rating
        self._reviewText = reviewText
        self.onSubmit = onSubmit
    }

    public var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("리뷰 작성 placeholder")
                .font(.headline)
            Stepper("평점 \(rating)", value: $rating, in: 1...5)
            TextField("리뷰를 입력하세요", text: $reviewText, axis: .vertical)
                .textFieldStyle(.roundedBorder)
            Button("제출") {
                onSubmit()
            }
            .buttonStyle(.borderedProminent)
        }
        .padding(24)
    }
}
