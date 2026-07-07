import PopupRequestFeature
import PopupRequestManagementFeature
import SwiftUI

@MainActor
enum PopupRequestFeatureFactory {
    static func makeRequestView(
        userUuid: String,
        onDismiss: @escaping () -> Void
    ) -> some View {
        PopupRequestFeatureView(
            userUuid: userUuid,
            onDismiss: onDismiss
        )
    }

    static func makeManagementView(
        onBack: @escaping () -> Void,
        onSelectSubmission: @escaping (String) -> Void = { _ in }
    ) -> some View {
        PopupRequestManagementFeatureView(
            onBack: onBack,
            onSelectSubmission: onSelectSubmission
        )
    }

    static func makeManagementDetailView(
        submissionId: String,
        onBack: @escaping () -> Void
    ) -> some View {
        PopupRequestManagementDetailFeatureView(
            submissionId: submissionId,
            onBack: onBack
        )
    }
}
