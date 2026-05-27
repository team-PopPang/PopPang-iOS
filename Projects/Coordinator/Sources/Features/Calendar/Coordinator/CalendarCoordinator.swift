import CalendarFeature
import Core
import AlertFeature
import PopupDetailFeature
import SwiftUI

@MainActor
public final class CalendarCoordinator: Coordinator<
    CalendarFeatureRoute,
    EmptySheetRoute,
    EmptyOverlayRoute,
    EmptyFullScreenRoute,
    EmptyBottomSheetRoute
> {
    private var session: MainTabSession

    public init(session: MainTabSession = MainTabSession(userUuid: "demo-user")) {
        self.session = session
        super.init()
    }

    public func updateSession(_ session: MainTabSession) {
        self.session = session
    }

    public func makeRootView() -> some View {
        CalendarFeatureView(
            userUuid: session.userUuid,
            onShowAlert: { [weak self] userUuid in
                self?.push(.alert(userUuid: userUuid))
            },
            onSelectPopup: { [weak self] userUuid, popup in
                self?.push(.popupDetail(userUuid: userUuid, popup: popup))
            }
        )
            .navigationTitle("Calendar")
    }

    @ViewBuilder
    public func buildView(for route: CalendarFeatureRoute) -> some View {
        switch route {
        case .alert(let userUuid):
            AlertFeatureView(
                userUuid: userUuid,
                onSelectPopup: { [weak self] userUuid, popup in
                    self?.push(.popupDetail(userUuid: userUuid, popup: popup))
                }
            )
        case .popupDetail(let userUuid, let popup):
            PopupDetailFeatureView(
                userUuid: userUuid,
                popup: popup,
                onSelectRelatedPopup: { [weak self] userUuid, popup in
                    self?.push(.popupDetail(userUuid: userUuid, popup: popup))
                },
                onShowReviews: { _ in }
            )
        }
    }
}
