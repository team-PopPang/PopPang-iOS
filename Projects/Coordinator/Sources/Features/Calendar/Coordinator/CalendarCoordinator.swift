import CalendarFeature
import Core
import AlertFeature
import Domain
import PopupDetailFeature
import ReviewFeature
import SwiftUI

@MainActor
public final class CalendarCoordinator: Coordinator<
    CalendarFeatureRoute,
    EmptySheetRoute,
    EmptyOverlayRoute,
    EmptyFullScreenRoute,
    EmptyBottomSheetRoute
> {
    public var onSelectPopup: ((String, Popup) -> Void)?

    private var session: MainTabSession
    private var rootView: CalendarFeatureView!

    public init(session: MainTabSession = MainTabSession(userUuid: "demo-user")) {
        self.session = session
        super.init()
        self.rootView = makeCalendarRootView(session: session)
    }

    public func updateSession(_ session: MainTabSession) {
        self.session = session
        self.rootView = makeCalendarRootView(session: session)
    }

    public func makeRootView() -> some View {
        rootView
    }

    private func makeCalendarRootView(session: MainTabSession) -> CalendarFeatureView {
        CalendarFeatureView(
            userUuid: session.userUuid,
            onShowAlert: { [weak self] userUuid in
                self?.push(.alert(userUuid: userUuid))
            },
            onSelectPopup: { [weak self] userUuid, popup in
                self?.routeToPopupDetail(userUuid: userUuid, popup: popup)
            }
        )
    }

    @ViewBuilder
    public func buildView(for route: CalendarFeatureRoute) -> some View {
        switch route {
        case .alert(let userUuid):
            AlertFeatureView(
                userUuid: userUuid,
                onSelectPopup: { [weak self] userUuid, popup in
                    self?.routeToPopupDetail(userUuid: userUuid, popup: popup)
                }
            )
        case .popupDetail(let userUuid, let popup):
            PopupDetailFeatureView(
                userUuid: userUuid,
                popup: popup,
                isAdmin: session.isAdmin,
                onSelectRelatedPopup: { [weak self] userUuid, popup in
                    self?.routeToPopupDetail(userUuid: userUuid, popup: popup)
                },
                onShowReviews: { [weak self] reviews in
                    self?.push(.reviewDetail(reviews))
                }
            )
        case .reviewDetail(let reviews):
            ReviewFeatureView(reviews: reviews)
        }
    }

    private func routeToPopupDetail(userUuid: String, popup: Popup) {
        if let onSelectPopup {
            onSelectPopup(userUuid, popup)
        } else {
            push(.popupDetail(userUuid: userUuid, popup: popup))
        }
    }
}
