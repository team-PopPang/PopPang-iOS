import Domain
import HomeFeatureInterface
import SwiftUI

public struct ComingPopupDetailFeatureView: View {
    private let userUuid: String
    private let popups: [Popup]
    private let router: any HomeFeatureRouting

    public init(
        userUuid: String,
        popups: [Popup],
        router: any HomeFeatureRouting
    ) {
        self.userUuid = userUuid
        self.popups = popups
        self.router = router
    }

    public var body: some View {
        let displayPopups = popups.isEmpty ? [Popup.popupMock, Popup.popupMock2] : popups

        return ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                Text("ComingPopupDetailFeature")
                    .font(.title.bold())
                Text("오픈 예정 팝업 목록은 임시 placeholder 상태입니다.")
                    .foregroundStyle(.secondary)

                ForEach(displayPopups, id: \.popupUuid) { popup in
                    Button(popup.name) {
                        router.route(to: .popupDetail(popup))
                    }
                    .buttonStyle(.borderedProminent)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(24)
        }
    }
}
