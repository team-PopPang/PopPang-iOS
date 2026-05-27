import AlertFeature
import Core
import ProfileFeature
import SwiftUI

@MainActor
public protocol ProfileCoordinatorParent: AnyObject {
    func logout()
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

    public init(session: MainTabSession = MainTabSession(userUuid: "demo-user")) {
        self.session = session
        super.init()
    }

    public func updateSession(_ session: MainTabSession) {
        self.session = session
    }

    public func makeRootView() -> some View {
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
        .navigationTitle("Profile")
    }

    @ViewBuilder
    public func buildView(for route: ProfileFeatureRoute) -> some View {
        switch route {
        case .alert(let userUuid):
            AlertFeatureView(userUuid: userUuid)
        case let .profileSetting(userUuid, nickname, isAlerted):
            ProfileSettingFeatureView(
                userUuid: userUuid,
                nickname: nickname,
                isAlerted: isAlerted,
                onLogout: { [weak self] in
                    self?.parent?.logout()
                }
            )
        case .notifications:
            NotificationFeatureView()
                .navigationTitle("공지사항")
        case .serviceTerms:
            ServiceTermsFeatureView()
                .navigationTitle("서비스 이용약관")
        }
    }
}
