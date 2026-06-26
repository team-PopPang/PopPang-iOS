import PopupRequestManagementFeatureInterface
import SwiftUI

public struct PopupRequestManagementFeatureView: View {
    private let items: [PopupRequestManagementItem]
    private let router: any PopupRequestManagementFeatureRouting

    public init(
        items: [PopupRequestManagementItem] = [],
        router: any PopupRequestManagementFeatureRouting
    ) {
        self.items = items
        self.router = router
    }

    public var body: some View {
        let displayItems = items.isEmpty ? [PopupRequestManagementItem.mock] : items

        return ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                Text("PopupRequestManagementFeature")
                    .font(.title.bold())
                Text("제보 관리 화면은 임시 placeholder 상태입니다.")
                    .foregroundStyle(.secondary)

                ForEach(displayItems) { item in
                    VStack(alignment: .leading, spacing: 8) {
                        Text(item.popupName)
                            .font(.headline)
                        Text("\(item.region) · \(item.status.title)")
                            .foregroundStyle(.secondary)
                        Button("상세 보기") {
                            router.route(to: .detail(item.id))
                        }
                        .buttonStyle(.bordered)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(16)
                    .background(Color(.secondarySystemBackground))
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                }

                Button("뒤로 가기") {
                    router.route(to: .back)
                }
                .buttonStyle(.borderedProminent)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(24)
        }
    }
}

public struct PopupRequestManagementDetailFeatureView: View {
    private let submissionId: String
    private let router: any PopupRequestManagementFeatureRouting

    public init(
        submissionId: String,
        router: any PopupRequestManagementFeatureRouting
    ) {
        self.submissionId = submissionId
        self.router = router
    }

    public var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("PopupRequestManagementDetailFeature")
                .font(.title.bold())
            Text("submissionId: \(submissionId)")
                .foregroundStyle(.secondary)
            Button("뒤로 가기") {
                router.route(to: .back)
            }
            .buttonStyle(.borderedProminent)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .padding(24)
    }
}
