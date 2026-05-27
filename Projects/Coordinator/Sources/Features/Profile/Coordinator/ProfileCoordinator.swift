import AlertFeature
import Core
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
    private var session: MainTabSession
    private var rootView: ProfileFeatureView!

    public init(session: MainTabSession = MainTabSession(userUuid: "demo-user")) {
        self.session = session
        super.init()
        self.rootView = makeProfileRootView(session: session)
    }

    public func updateSession(_ session: MainTabSession) {
        self.session = session
        self.rootView = makeProfileRootView(session: session)
    }

    public func makeRootView() -> some View {
        rootView
    }

    private func makeProfileRootView(session: MainTabSession) -> ProfileFeatureView {
        ProfileFeatureView(
            userUuid: session.userUuid,
            nickname: session.nickname,
            isAlerted: session.isAlerted,
            onShowAlert: { [weak self] userUuid in
                self?.push(.alert(userUuid: userUuid))
            },
            onProfileSetting: { [weak self] userUuid, nickname, isAlerted in
                self?.push(.profileSetting(userUuid: userUuid, nickname: nickname, isAlerted: isAlerted))
            },
            onNotification: { [weak self] in
                self?.push(.notifications)
            },
            onServiceTerms: { [weak self] in
                self?.push(.serviceTerms)
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
                    self?.push(.popupDetail(userUuid: userUuid, popup: popup))
                }
            )
        case .popupDetail(let userUuid, let popup):
            PopupDetailFeatureView(
                userUuid: userUuid,
                popup: popup,
                isAdmin: session.isAdmin,
                onSelectRelatedPopup: { [weak self] userUuid, popup in
                    self?.push(.popupDetail(userUuid: userUuid, popup: popup))
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
}
