import AlertFeature
import Core
import Domain
import PopupDetailFeature
import ProfileFeature
import ReviewFeature
import SwiftUI

@MainActor
public protocol ProfileCoordinatorParent: AnyObject {
    func logout()
    func updateProfileSession(_ session: MainTabSession)
}

@MainActor
public final class ProfileCoordinator: Coordinator<
    ProfileFeatureRoute,
    EmptySheetRoute,
    EmptyOverlayRoute,
    EmptyFullScreenRoute,
    EmptyBottomSheetRoute
> {
    public weak var parent: (any ProfileCoordinatorParent)?
    public var onSelectPopup: ((String, Popup) -> Void)?
    public var onShowAlert: ((String) -> Void)?
    public var onProfileSetting: ((String, String, Bool) -> Void)?
    public var onNotification: (() -> Void)?
    public var onServiceTerms: (() -> Void)?

    private var session: MainTabSession

    public init(session: MainTabSession = MainTabSession(userUuid: "demo-user")) {
        self.session = session
        super.init()
    }

    public func updateSession(_ session: MainTabSession) {
        self.session = session
    }

    public func makeRootView() -> some View {
        makeProfileRootView(session: session)
            .id(session)
    }

    private func makeProfileRootView(session: MainTabSession) -> ProfileFeatureView {
        ProfileFeatureView(
            userUuid: session.userUuid,
            nickname: session.nickname,
            isAlerted: session.isAlerted,
            onShowAlert: { [weak self] userUuid in
                self?.routeToAlert(userUuid: userUuid)
            },
            onProfileSetting: { [weak self] userUuid, nickname, isAlerted in
                self?.routeToProfileSetting(
                    userUuid: userUuid,
                    nickname: nickname,
                    isAlerted: isAlerted
                )
            },
            onNotification: { [weak self] in
                self?.routeToNotification()
            },
            onServiceTerms: { [weak self] in
                self?.routeToServiceTerms()
            }
        )
    }

    @ViewBuilder
    public func buildView(for route: ProfileFeatureRoute) -> some View {
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
        case let .profileSetting(userUuid, nickname, isAlerted):
            ProfileSettingFeatureView(
                userUuid: userUuid,
                nickname: nickname,
                isAlerted: isAlerted,
                onLogout: { [weak self] in
                    self?.parent?.logout()
                },
                onNicknameUpdated: { [weak self] nickname in
                    guard let self else { return }
                    var updatedSession = session
                    updatedSession.nickname = nickname
                    updateSession(updatedSession)
                    parent?.updateProfileSession(updatedSession)
                }
            )
        case .notifications:
            NotificationFeatureView()
        case .serviceTerms:
            ServiceTermsFeatureView()
        case .reviewDetail(let reviews):
            ReviewFeatureView(reviews: reviews)
        }
    }

    private func routeToProfileSetting(userUuid: String, nickname: String, isAlerted: Bool) {
        if let onProfileSetting {
            onProfileSetting(userUuid, nickname, isAlerted)
        } else {
            push(.profileSetting(userUuid: userUuid, nickname: nickname, isAlerted: isAlerted))
        }
    }

    private func routeToNotification() {
        if let onNotification {
            onNotification()
        } else {
            push(.notifications)
        }
    }

    private func routeToServiceTerms() {
        if let onServiceTerms {
            onServiceTerms()
        } else {
            push(.serviceTerms)
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
