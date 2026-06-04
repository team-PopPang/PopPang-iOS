import AlertFeature
import Core
import Domain
import HomeFeature
import PopupDetailFeature
import PopupReportFeature
import ReviewFeature
import SearchFeature
import SwiftUI

@MainActor
public final class HomeCoordinator: Coordinator<
    HomeFeatureRoute,
    EmptySheetRoute,
    EmptyOverlayRoute,
    HomeFullScreenRoute,
    EmptyBottomSheetRoute
> {
    public var onSelectPopup: ((String, Popup) -> Void)?
    public var onShowAlert: ((String) -> Void)?
    public var onReport: ((String) -> Void)?

    private var session: MainTabSession
    private var rootView: HomeFeatureView

    public init(session: MainTabSession = MainTabSession(userUuid: "demo-user")) {
        self.session = session
        self.rootView = HomeFeatureView(userUuid: session.userUuid, nickname: session.nickname)
        super.init()
        self.rootView = makeHomeRootView(session: session)
    }

    public func updateSession(_ session: MainTabSession) {
        self.session = session
        self.rootView = makeHomeRootView(session: session)
    }

    public func makeRootView() -> some View {
        rootView
    }

    @ViewBuilder
    public func buildView(for route: HomeFeatureRoute) -> some View {
        switch route {
        case .popupDetail(let userUuid, let popup):
            makePopupDetailDestination(userUuid: userUuid, popup: popup)
        case let .comingPopupDetail(userUuid, popups):
            ComingPopupDetailFeatureView(
                userUuid: userUuid,
                popups: popups,
                onSelectPopup: { [weak self] userUuid, popup in
                    self?.pushPopupDetail(userUuid: userUuid, popup: popup)
                }
            )
        case .alert(let userUuid):
            AlertFeatureView(
                userUuid: userUuid,
                onSelectPopup: { [weak self] userUuid, popup in
                    self?.routeToPopupDetail(userUuid: userUuid, popup: popup)
                }
            )
        case .reviewDetail(let reviews):
            ReviewFeatureView(reviews: reviews)
        case .popupReport(let userUuid):
            PopupReportFeatureView(
                userUuid: userUuid,
                onDismiss: { [weak self] in
                    self?.pop()
                }
            )
        }
    }

    @ViewBuilder
    public func buildFullScreen(for route: HomeFullScreenRoute) -> some View {
        switch route {
        case .search(let userUuid):
            SearchFeatureView(
                userUuid: userUuid,
                nickname: session.nickname,
                onDismiss: { [weak self] in
                    self?.dismissFullScreen()
                },
                onSelectPopup: { [weak self] popup in
                    guard let self else { return }
                    dismissFullScreen()
                    routeToPopupDetail(userUuid: userUuid, popup: popup)
                }
            )
            .accessibilityIdentifier("home_search")
        }
    }

    private func makeHomeRootView(session: MainTabSession) -> HomeFeatureView {
        HomeFeatureView(
            userUuid: session.userUuid,
            nickname: session.nickname,
            onSelectPopup: { [weak self] userUuid, popup in
                self?.routeToPopupDetail(userUuid: userUuid, popup: popup)
            },
            onShowAlert: { [weak self] userUuid in
                self?.routeToAlert(userUuid: userUuid)
            },
            onReport: { [weak self] userUuid in
                self?.routeToReport(userUuid: userUuid)
            }
        )
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
            pushPopupDetail(userUuid: userUuid, popup: popup)
        }
    }

    private func routeToReport(userUuid: String) {
        if let onReport {
            onReport(userUuid)
        } else {
            push(.popupReport(userUuid: userUuid))
        }
    }

    private func pushPopupDetail(userUuid: String, popup: Popup) {
        push(.popupDetail(userUuid: userUuid, popup: popup))
    }

    private func makePopupDetailDestination(userUuid: String, popup: Popup) -> AnyView {
        AnyView(
            PopupDetailFeatureView(
                userUuid: userUuid,
                popup: popup,
                isAdmin: session.isAdmin,
                onSelectRelatedPopup: { [weak self] userUuid, popup in
                    self?.pushPopupDetail(userUuid: userUuid, popup: popup)
                },
                onShowReviews: { [weak self] reviews in
                    self?.push(.reviewDetail(reviews))
                }
            )
        )
    }
}
