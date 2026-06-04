import AlertFeature
import Core
import Domain
import FavoritesFeature
import PopupDetailFeature
import ReviewFeature
import SwiftUI

@MainActor
public final class FavoritesCoordinator: Coordinator<
    FavoritesFeatureRoute,
    EmptySheetRoute,
    EmptyOverlayRoute,
    EmptyFullScreenRoute,
    EmptyBottomSheetRoute
> {
    public var onSelectPopup: ((String, Popup) -> Void)?
    public var onShowAlert: ((String) -> Void)?

    private var session: MainTabSession
    public var onBrowsePopups: (() -> Void)?

    public init(session: MainTabSession = MainTabSession(userUuid: "demo-user")) {
        self.session = session
        super.init()
    }

    public func updateSession(_ session: MainTabSession) {
        self.session = session
    }

    public func makeRootView() -> some View {
        makeFavoritesRootView(session: session)
            .id(session)
    }

    private func makeFavoritesRootView(session: MainTabSession) -> FavoritesFeatureView {
        FavoritesFeatureView(
            userUuid: session.userUuid,
            onShowAlert: { [weak self] userUuid in
                self?.routeToAlert(userUuid: userUuid)
            },
            onSelectPopup: { [weak self] userUuid, popup in
                self?.routeToPopupDetail(userUuid: userUuid, popup: popup)
            },
            onBrowsePopups: { [weak self] in
                self?.onBrowsePopups?()
            }
        )
    }

    @ViewBuilder
    public func buildView(for route: FavoritesFeatureRoute) -> some View {
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

    private func routeToAlert(userUuid: String) {
        if let onShowAlert {
            onShowAlert(userUuid)
        } else {
            push(.alert(userUuid: userUuid))
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
