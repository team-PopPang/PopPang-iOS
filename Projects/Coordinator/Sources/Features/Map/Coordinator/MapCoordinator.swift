import Core
import Domain
import MapFeature
import PopupDetailFeature
import ReviewFeature
import SwiftUI

@MainActor
public final class MapCoordinator: Coordinator<
    MapFeatureRoute,
    EmptySheetRoute,
    EmptyOverlayRoute,
    EmptyFullScreenRoute,
    EmptyBottomSheetRoute
> {
    public var onSelectPopup: ((String, Popup) -> Void)?

    private var session: MainTabSession

    public init(session: MainTabSession = MainTabSession(userUuid: "demo-user")) {
        self.session = session
        super.init()
    }

    public func updateSession(_ session: MainTabSession) {
        self.session = session
    }

    public func makeRootView() -> some View {
        makeMapRootView(session: session)
            .id(session)
    }

    private func makeMapRootView(session: MainTabSession) -> MapFeatureView {
        MapFeatureView(
            userUuid: session.userUuid,
            onSelectPopup: { [weak self] userUuid, popup in
                self?.routeToPopupDetail(userUuid: userUuid, popup: popup)
            }
        )
    }

    @ViewBuilder
    public func buildView(for route: MapFeatureRoute) -> some View {
        switch route {
        case .popupDetail(let userUuid, let popup):
            PopupDetailFeatureView(
                userUuid: userUuid,
                popup: popup,
                isAdmin: session.isAdmin,
                onSelectRelatedPopup: { [weak self] userUuid, popup in
                    self?.routeToPopupDetail(userUuid: userUuid, popup: popup)
                },
                onDeactivateComplete: { [weak self] in
                    self?.pop()
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
