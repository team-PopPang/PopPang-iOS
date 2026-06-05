import AlertFeature
import HomeFeature
import PopupDetailFeature
import ProfileFeature
import ReviewFeature
import SearchFeature
import SwiftUI

extension MainTabCoordinator {
    @ViewBuilder
    func buildView(for route: MainTabRoute) -> some View {
        switch route {
        case .popupDetail(let userUuid, let popup):
            PopupDetailFeatureView(
                userUuid: userUuid,
                popup: popup,
                isAdmin: session.isAdmin,
                hidesSystemTabBar: false,
                onSelectRelatedPopup: { [weak self] userUuid, popup in
                    self?.push(.popupDetail(userUuid: userUuid, popup: popup))
                },
                onDeactivateComplete: { [weak self] in
                    self?.pop()
                },
                onShowReviews: { [weak self] reviews in
                    self?.push(.reviewDetail(reviews))
                }
            )
        case .comingPopupDetail(let userUuid, let popups):
            ComingPopupDetailFeatureView(
                userUuid: userUuid,
                popups: popups,
                onSelectPopup: { [weak self] userUuid, popup in
                    self?.push(.popupDetail(userUuid: userUuid, popup: popup))
                }
            )
        case .reviewDetail(let reviews):
            ReviewFeatureView(reviews: reviews)
        case .alert(let userUuid):
            AlertFeatureView(
                userUuid: userUuid,
                onSelectPopup: { [weak self] userUuid, popup in
                    self?.push(.popupDetail(userUuid: userUuid, popup: popup))
                }
            )
        case .popupRequest(let userUuid):
            PopupRequestFeatureFactory.makeRequestView(
                userUuid: userUuid,
                onDismiss: { [weak self] in
                    self?.pop()
                }
            )
        case .popupRequestManagement:
            PopupRequestFeatureFactory.makeManagementView(
                onBack: { [weak self] in
                    self?.pop()
                },
                onSelectSubmission: { [weak self] submissionId in
                    self?.push(.popupRequestManagementDetail(submissionId: submissionId))
                }
            )
        case .popupRequestManagementDetail(let submissionId):
            PopupRequestFeatureFactory.makeManagementDetailView(
                submissionId: submissionId,
                onBack: { [weak self] in
                    self?.pop()
                }
            )
        case .profileSetting(let userUuid, let nickname, let isAlerted):
            ProfileSettingFeatureView(
                userUuid: userUuid,
                nickname: nickname,
                isAlerted: isAlerted,
                onLogout: { [weak self] in
                    self?.logout()
                },
                onNicknameUpdated: { [weak self] nickname in
                    guard let self else { return }
                    var updatedSession = session
                    updatedSession.nickname = nickname
                    updateProfileSession(updatedSession)
                }
            )
        case .notifications:
            NotificationFeatureView()
        case .serviceTerms:
            ServiceTermsFeatureView()
        }
    }

    @ViewBuilder
    func buildFullScreen(for route: MainTabFullScreenRoute) -> some View {
        switch route {
        case .search(let userUuid):
            SearchFeatureView(
                userUuid: userUuid,
                nickname: session.nickname,
                onDismiss: { [weak self] in
                    self?.dismissFullScreen()
                },
                onSelectPopup: { [weak self] popup in
                    self?.dismissFullScreen()
                    self?.push(.popupDetail(userUuid: userUuid, popup: popup))
                }
            )
            .accessibilityIdentifier("home_search")
        }
    }
}
