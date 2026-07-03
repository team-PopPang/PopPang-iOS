import ComposableArchitecture
import Domain
import DSKit
import SwiftUI

public struct ReviewFeatureView: View {
    let store: StoreOf<ReviewFeature>

    public init(store: StoreOf<ReviewFeature>) {
        self.store = store
    }

    public var body: some View {
        VStack {
            ScrollView {
                LazyVStack {
                    ForEach(store.reviews) { review in
                        ReviewCell(
                            nickname: review.nickname,
                            review: review.info,
                            starCount: review.starCount
                        )
                    }
                }
                .padding(.top, 20)
                .padding(.horizontal, .contentPadding)
            }

            MainOrangeButton(
                buttonTitle: "리뷰 남기기",
                isReversed: false,
                height: 80
            ) {
                store.send(.reviewWriteButtonTapped)
            }
        }
        .ignoresSafeArea(edges: .bottom)
        .sheet(isPresented: reviewSheetPresentedBinding) {
            ReviewWriteSheet(
                rating: ratingBinding,
                reviewText: reviewTextBinding,
                onSubmit: {
                    store.send(.submitReview)
                }
            )
            .presentationDetents([.height(320)])
        }
    }
}

private extension ReviewFeatureView {
    var reviewSheetPresentedBinding: Binding<Bool> {
        Binding(
            get: { store.isPresentingReviewSheet },
            set: { store.send(.reviewSheetPresented($0)) }
        )
    }

    var ratingBinding: Binding<Int> {
        Binding(
            get: { store.rating },
            set: { store.send(.ratingSelected($0)) }
        )
    }

    var reviewTextBinding: Binding<String> {
        Binding(
            get: { store.reviewText },
            set: { store.send(.reviewTextChanged($0)) }
        )
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
        HStack {
            Text("리뷰 \(reviews.count)개")
                .font(.scdream(.medium, size: 15))

            Spacer()

            Button {
                onShowAllReviews()
            } label: {
                DSKitResource.image("navigationButton")
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 16, height: 16)
            }
        }

        LazyVStack {
            ForEach(Array(reviews.prefix(3))) { review in
                ReviewCell(
                    nickname: review.nickname,
                    review: review.info,
                    starCount: review.starCount
                )
            }
        }
        .padding(.top, 20)
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
        VStack(alignment: .leading, spacing: 0) {
            HStack(spacing: 3) {
                ForEach(0..<starCount, id: \.self) { _ in
                    Image(systemName: "star.fill")
                        .resizable()
                        .frame(width: 12, height: 12)
                        .foregroundStyle(Color.mainOrange)
                }

                Spacer()

                Text("2026.01.03")
                    .font(.scdream(.light, size: 12))

                Text("|")
                    .font(.scdream(.light, size: 12))

                Text("신고")
                    .font(.scdream(.light, size: 12))
            }

            Text(nickname)
                .font(.scdream(.medium, size: 12))
                .padding(.top, 10)

            Text(review)
                .font(.scdream(.light, size: 12))
                .padding(.top, 10)
        }
        .padding(10)
        .background(.gray.opacity(0.1))
        .cornerRadius(10)
    }
}

public struct ReviewWriteSheet: View {
    @Environment(\.dismiss) private var dismiss

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
        VStack(alignment: .leading, spacing: 15) {
            HStack {
                Text("이 팝업을 추천하시나요?")
                    .ppStyleFont(.scdream(.bold, size: 20))
                    .foregroundStyle(Color.mainBlack)

                Spacer()

                Button {
                    dismiss()
                } label: {
                    Image(systemName: "xmark")
                        .foregroundStyle(.black)
                        .font(.system(size: 11, weight: .regular))
                        .frame(width: 27, height: 27)
                        .background(Color.mainGray5)
                        .clipShape(Circle())
                }
            }

            HStack(spacing: 12) {
                ForEach(1...5, id: \.self) { index in
                    Image(systemName: "star.fill")
                        .resizable()
                        .frame(width: 25, height: 25)
                        .foregroundStyle(index <= rating ? Color.mainOrange : Color.gray.opacity(0.4))
                        .onTapGesture {
                            rating = index
                        }
                }
            }

            ZStack(alignment: .topLeading) {
                if reviewText.isEmpty {
                    Text("리뷰를 남겨주세요")
                        .foregroundStyle(Color.gray.opacity(0.8))
                        .padding(.top, 10)
                        .padding(.leading, 10)
                }

                TextEditor(text: $reviewText)
                    .frame(height: 120)
                    .padding(4)
                    .scrollContentBackground(.hidden)
                    .background(Color.clear)
            }
            .background(Color.gray.opacity(0.1))
            .cornerRadius(10)

            Button {
                onSubmit()
            } label: {
                Text("리뷰 쓰기")
                    .ppStyleFont(.scdream(.bold, size: 16))
                    .frame(maxWidth: .infinity)
                    .frame(height: 44)
                    .background(rating == 0 ? Color.gray.opacity(0.3) : Color.mainOrange)
                    .foregroundStyle(Color.white)
                    .cornerRadius(10)
            }
            .disabled(rating == 0)
        }
        .padding()
    }
}
