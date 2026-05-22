import SwiftUI

public struct ReviewFeatureView: View {
    @State private var reviews = ReviewItem.mock
    @State private var selectedReview: ReviewItem?
    @State private var draftText = ""
    @State private var isPresentingComposer = false

    public init() {}

    public var body: some View {
        List {
            Section {
                Button("리뷰 작성") {
                    isPresentingComposer = true
                }
            }

            Section("리뷰 목록") {
                ForEach(reviews) { review in
                    Button {
                        selectedReview = review
                    } label: {
                        VStack(alignment: .leading, spacing: 8) {
                            HStack {
                                Text(review.author)
                                    .font(.headline)
                                Spacer()
                                Text(review.date)
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                            Text(review.summary)
                                .foregroundStyle(.primary)
                            HStack {
                                Label("\(review.likes)", systemImage: "heart")
                                Label("\(review.rating).0", systemImage: "star.fill")
                            }
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        }
                        .padding(.vertical, 4)
                    }
                    .buttonStyle(.plain)
                }
            }
        }
        .navigationTitle("리뷰")
        .sheet(isPresented: $isPresentingComposer) {
            NavigationStack {
                Form {
                    Section("내용") {
                        TextField("팝업 후기를 남겨주세요", text: $draftText, axis: .vertical)
                            .lineLimit(5...8)
                    }
                }
                .navigationTitle("리뷰 작성")
                .toolbar {
                    ToolbarItem(placement: .cancellationAction) {
                        Button("닫기") {
                            isPresentingComposer = false
                        }
                    }
                    ToolbarItem(placement: .confirmationAction) {
                        Button("등록") {
                            guard draftText.isEmpty == false else { return }
                            reviews.insert(
                                ReviewItem(author: "나", summary: draftText, date: "방금", likes: 0, rating: 5),
                                at: 0
                            )
                            draftText = ""
                            isPresentingComposer = false
                        }
                    }
                }
            }
        }
        .sheet(item: $selectedReview) { review in
            NavigationStack {
                ScrollView {
                    VStack(alignment: .leading, spacing: 16) {
                        Text(review.author)
                            .font(.title2.weight(.bold))
                        Text(review.date)
                            .foregroundStyle(.secondary)
                        Text(review.summary)
                            .font(.body)
                        HStack {
                            Label("\(review.likes)", systemImage: "heart")
                            Label("\(review.rating).0", systemImage: "star.fill")
                        }
                        .foregroundStyle(.secondary)
                    }
                    .padding(24)
                }
                .navigationTitle("리뷰 상세")
                .navigationBarTitleDisplayMode(.inline)
            }
        }
    }
}

private struct ReviewItem: Identifiable, Equatable {
    let id = UUID()
    let author: String
    let summary: String
    let date: String
    let likes: Int
    let rating: Int

    static let mock: [ReviewItem] = [
        .init(author: "팝업러버", summary: "굿즈 구성이 좋고 동선이 깔끔했습니다. 주말엔 대기가 조금 있습니다.", date: "5월 21일", likes: 12, rating: 5),
        .init(author: "성수탐험가", summary: "포토존이 많고 직원 안내가 친절했어요.", date: "5월 19일", likes: 7, rating: 4),
        .init(author: "디저트수집가", summary: "브랜드 설명 섹션이 인상적이었습니다.", date: "5월 17일", likes: 4, rating: 4),
    ]
}
