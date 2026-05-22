import SwiftUI

public struct PopupDetailFeatureView: View {
    private let onShowReviews: () -> Void
    @State private var isFavorite = false

    public init(onShowReviews: @escaping () -> Void = {}) {
        self.onShowReviews = onShowReviews
    }

    public var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                RoundedRectangle(cornerRadius: 28, style: .continuous)
                    .fill(
                        LinearGradient(
                            colors: [Color.orange.opacity(0.9), Color.red.opacity(0.6)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(height: 260)
                    .overlay(alignment: .bottomLeading) {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("브랜드 협업 팝업")
                                .font(.title.weight(.bold))
                                .foregroundStyle(.white)
                            Text("성수동 | 05.22 - 06.10")
                                .foregroundStyle(.white.opacity(0.82))
                        }
                        .padding(24)
                    }

                HStack(spacing: 12) {
                    Button(isFavorite ? "찜 완료" : "찜하기") {
                        isFavorite.toggle()
                    }
                    .buttonStyle(.borderedProminent)

                    Button("공유") {}
                        .buttonStyle(.bordered)

                    Button("리뷰") {
                        onShowReviews()
                    }
                    .buttonStyle(.bordered)
                }

                VStack(alignment: .leading, spacing: 10) {
                    Text("소개")
                        .font(.headline)
                    Text("V0 PopupDetailView의 핵심 정보 구조를 먼저 복원한 상태입니다. 상세 이미지, 운영 시간, SNS 링크, 유사 팝업 추천을 순차적으로 이식합니다.")
                        .foregroundStyle(.secondary)
                }

                VStack(alignment: .leading, spacing: 10) {
                    Text("운영 정보")
                        .font(.headline)
                    detailRow("운영 시간", "11:00 - 20:00")
                    detailRow("위치", "서울 성동구 성수이로 00")
                    detailRow("특징", "전시 · 포토존 · 한정 굿즈")
                }
            }
            .padding(24)
        }
        .navigationTitle("Popup Detail")
        .navigationBarTitleDisplayMode(.inline)
    }

    private func detailRow(_ title: String, _ value: String) -> some View {
        HStack(alignment: .top) {
            Text(title)
                .frame(width: 72, alignment: .leading)
                .foregroundStyle(.secondary)
            Text(value)
        }
    }
}
