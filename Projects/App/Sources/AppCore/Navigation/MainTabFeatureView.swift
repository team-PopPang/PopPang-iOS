import AlertFeature
import CalendarFeature
import ComposableArchitecture
import DSKit
import FavoritesFeature
import HomeFeature
import MapFeature
import PopupDetailFeature
import PopupRequestManagementFeature
import ProfileFeature
import ReviewFeature
import SwiftUI

struct MainTabFeatureView: View {
    @Bindable var store: StoreOf<MainTabFeature>

    var body: some View {
        NavigationStack(path: $store.scope(state: \.core.path, action: \.path)) {
            TabView(
                selection: Binding(
                    get: { store.core.selectedTab },
                    set: { store.send(.selectedTabChanged($0)) }
                )
            ) {
                ForEach(MainTab.allCases, id: \.self) { tab in
                    tabView(for: tab)
                        .tabItem {
                            DSKitResource.image(tab.tabImageName(selected: store.core.selectedTab == tab))
                                .resizable()
                                .aspectRatio(contentMode: .fit)
                                .frame(width: 25, height: 25)
                            Text(tab.title)
                        }
                        .tag(tab)
                }
            }
        } destination: { store in
            switch store.state {
            case .popupRequestManagement:
                if let store = store.scope(state: \.popupRequestManagement, action: \.popupRequestManagement) {
                    PopupRequestManagementDestinationView(store: store)
                }
            case .popupRequestManagementDetail:
                if let store = store.scope(state: \.popupRequestManagementDetail, action: \.popupRequestManagementDetail) {
                    PopupRequestManagementDetailDestinationView(store: store)
                }
            case .homeComingPopupDetail:
                if let store = store.scope(state: \.homeComingPopupDetail, action: \.homeComingPopupDetail) {
                    HomeComingPopupDetailDestinationView(store: store)
                }
            case .popupDetail:
                if let store = store.scope(state: \.popupDetail, action: \.popupDetail) {
                    PopupDetailDestinationView(store: store)
                }
            case .reviewDetail:
                if let store = store.scope(state: \.reviewDetail, action: \.reviewDetail) {
                    ReviewDetailDestinationView(store: store)
                }
            case .alert:
                if let store = store.scope(state: \.alert, action: \.alert) {
                    AlertDestinationView(store: store)
                }
            case .profileSetting:
                if let store = store.scope(state: \.profileSetting, action: \.profileSetting) {
                    ProfileSettingDestinationView(store: store)
                }
            case .notifications:
                if let store = store.scope(state: \.notifications, action: \.notifications) {
                    NotificationDestinationView(store: store)
                }
            case .serviceTerms:
                if let store = store.scope(state: \.serviceTerms, action: \.serviceTerms) {
                    ServiceTermsDestinationView(store: store)
                }
            }
        }
    }

    @ViewBuilder
    private func tabView(for tab: MainTab) -> some View {
        switch tab {
        case .home:
            HomeRootFeatureView(store: store.scope(state: \.core.home, action: \.home))
        case .calendar:
            CalendarLegacyBridgeView(store: store.scope(state: \.calendar, action: \.calendar))
        case .map:
            MapLegacyBridgeView(store: store.scope(state: \.map, action: \.map))
        case .favorites:
            FavoritesLegacyBridgeView(store: store.scope(state: \.favorites, action: \.favorites))
        case .profile:
            ProfileLegacyBridgeView(store: store.scope(state: \.profile, action: \.profile))
        }
    }
}

private struct CalendarLegacyBridgeView: View {
    let store: StoreOf<CalendarLegacyBridgeFeature>

    var body: some View {
        CalendarFeatureView(
            userUuid: store.userUuid,
            onShowAlert: { _ in
                store.send(.alertTapped)
            },
            onSelectPopup: { _, popup in
                store.send(.popupSelected(popup))
            }
        )
    }
}

private struct MapLegacyBridgeView: View {
    let store: StoreOf<MapLegacyBridgeFeature>

    var body: some View {
        MapFeatureView(
            userUuid: store.userUuid,
            onSelectPopup: { _, popup in
                store.send(.popupSelected(popup))
            }
        )
    }
}

private struct FavoritesLegacyBridgeView: View {
    let store: StoreOf<FavoritesLegacyBridgeFeature>

    var body: some View {
        FavoritesFeatureView(
            userUuid: store.userUuid,
            onShowAlert: { _ in
                store.send(.alertTapped)
            },
            onSelectPopup: { _, popup in
                store.send(.popupSelected(popup))
            },
            onBrowsePopups: {
                store.send(.browsePopupsTapped)
            }
        )
    }
}

private struct ProfileLegacyBridgeView: View {
    let store: StoreOf<ProfileLegacyBridgeFeature>

    var body: some View {
        ProfileFeatureView(
            userUuid: store.userUuid,
            nickname: store.nickname,
            isAlerted: store.isAlerted,
            onShowAlert: { _ in
                store.send(.alertTapped)
            },
            onProfileSetting: { _, nickname, isAlerted in
                store.send(.profileSettingTapped(nickname: nickname, isAlerted: isAlerted))
            },
            onNotification: {
                store.send(.notificationsTapped)
            },
            onServiceTerms: {
                store.send(.serviceTermsTapped)
            }
        )
    }
}

private struct PopupDetailDestinationView: View {
    let store: StoreOf<PopupDetailDestinationFeature>

    var body: some View {
        PopupDetailFeatureView(
            userUuid: store.userUuid,
            popup: store.popup,
            isAdmin: store.isAdmin,
            hidesSystemTabBar: false,
            onSelectRelatedPopup: { userUuid, popup in
                store.send(.relatedPopupSelected(userUuid, popup))
            },
            onDeactivateComplete: {
                store.send(.deactivateCompleted)
            },
            onShowReviews: { reviews in
                store.send(.reviewsTapped(reviews))
            }
        )
    }
}

private struct PopupRequestManagementDestinationView: View {
    let store: StoreOf<PopupRequestManagementFlowFeature>

    var body: some View {
        PopupRequestManagementFlowView(store: store)
    }
}

private struct PopupRequestManagementDetailDestinationView: View {
    let store: StoreOf<PopupRequestManagementDetailFeature>

    var body: some View {
        PopupRequestManagementDetailView(store: store)
    }
}

private struct ReviewDetailDestinationView: View {
    let store: StoreOf<ReviewDetailDestinationFeature>

    var body: some View {
        ReviewFeatureView(reviews: store.reviews)
    }
}

private struct AlertDestinationView: View {
    let store: StoreOf<AlertDestinationFeature>

    var body: some View {
        AlertFeatureView(
            userUuid: store.userUuid,
            onSelectPopup: { userUuid, popup in
                store.send(.popupSelected(userUuid, popup))
            }
        )
    }
}

private struct ProfileSettingDestinationView: View {
    let store: StoreOf<ProfileSettingDestinationFeature>

    var body: some View {
        ProfileSettingFeatureView(
            userUuid: store.userUuid,
            nickname: store.nickname,
            isAlerted: store.isAlerted,
            onLogout: {
                store.send(.logoutTapped)
            },
            onNicknameUpdated: { nickname in
                store.send(.nicknameUpdated(nickname))
            }
        )
    }
}

private struct NotificationDestinationView: View {
    let store: StoreOf<NotificationDestinationFeature>

    var body: some View {
        NotificationFeatureView()
    }
}

private struct ServiceTermsDestinationView: View {
    let store: StoreOf<ServiceTermsDestinationFeature>

    var body: some View {
        ServiceTermsFeatureView()
    }
}
