import AlertFeature
import CalendarFeature
import ComposableArchitecture
import DSKit
import FavoritesFeature
import HomeFeature
import MapFeature
import PopupDetailFeature
import PopupRequestFeature
import PopupRequestManagementFeature
import ProfileFeature
import ReviewFeature
import SearchFeature
import SwiftUI

struct MainTabFeatureView: View {
    @Bindable var store: StoreOf<MainTabFeature>

    var body: some View {
        NavigationStackStore(store.scope(state: \.path, action: \.path)) {
            TabView(selection: $store.selectedTab) {
                ForEach(MainTab.allCases, id: \.self) { tab in
                    tabView(for: tab)
                        .tabItem {
                            DSKitResource.image(tab.tabImageName(selected: store.selectedTab == tab))
                                .resizable()
                                .aspectRatio(contentMode: .fit)
                                .frame(width: 25, height: 25)
                            Text(tab.title)
                        }
                        .tag(tab)
                }
            }
        } destination: { store in
            switch store.case {
            case .popupDetail(let store):
                PopupDetailDestinationView(store: store)
            case .comingPopupDetail(let store):
                ComingPopupDetailDestinationView(store: store)
            case .reviewDetail(let store):
                ReviewDetailDestinationView(store: store)
            case .alert(let store):
                AlertDestinationView(store: store)
            case .popupRequest(let store):
                PopupRequestDestinationView(store: store)
            case .popupRequestManagement(let store):
                PopupRequestManagementDestinationView(store: store)
            case .popupRequestManagementDetail(let store):
                PopupRequestManagementDetailDestinationView(store: store)
            case .profileSetting(let store):
                ProfileSettingDestinationView(store: store)
            case .notifications(let store):
                NotificationDestinationView(store: store)
            case .serviceTerms(let store):
                ServiceTermsDestinationView(store: store)
            }
        }
        .fullScreenCover(
            item: $store.scope(state: \.destination?.search, action: \.destination.search)
        ) { store in
            SearchDestinationView(store: store)
        }
    }

    @ViewBuilder
    private func tabView(for tab: MainTab) -> some View {
        switch tab {
        case .home:
            HomeTabView(store: store.scope(state: \.home, action: \.home))
                .id(store.session)
        case .calendar:
            CalendarTabView(store: store.scope(state: \.calendar, action: \.calendar))
                .id(store.session)
        case .map:
            MapTabView(store: store.scope(state: \.map, action: \.map))
                .id(store.session)
        case .favorites:
            FavoritesTabView(store: store.scope(state: \.favorites, action: \.favorites))
                .id(store.session)
        case .profile:
            ProfileTabView(store: store.scope(state: \.profile, action: \.profile))
                .id(store.session)
        }
    }
}

private struct HomeTabView: View {
    let store: StoreOf<HomeTabFeature>

    var body: some View {
        HomeFeatureView(
            userUuid: store.userUuid,
            nickname: store.nickname,
            isAdmin: store.isAdmin,
            onSelectPopup: { _, popup in
                store.send(.popupSelected(popup))
            },
            onShowAlert: { _ in
                store.send(.alertTapped)
            },
            onSearch: { _ in
                store.send(.searchTapped)
            },
            onShowComingPopups: { _, popups in
                store.send(.comingPopupsTapped(popups))
            },
            onReport: { _ in
                store.send(.popupRequestTapped)
            },
            onManagePopupRequests: {
                store.send(.popupRequestManagementTapped)
            }
        )
    }
}

private struct CalendarTabView: View {
    let store: StoreOf<CalendarTabFeature>

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

private struct MapTabView: View {
    let store: StoreOf<MapTabFeature>

    var body: some View {
        MapFeatureView(
            userUuid: store.userUuid,
            onSelectPopup: { _, popup in
                store.send(.popupSelected(popup))
            }
        )
    }
}

private struct FavoritesTabView: View {
    let store: StoreOf<FavoritesTabFeature>

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

private struct ProfileTabView: View {
    let store: StoreOf<ProfileTabFeature>

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

private struct SearchDestinationView: View {
    let store: StoreOf<SearchDestinationFeature>

    var body: some View {
        SearchFeatureView(
            userUuid: store.userUuid,
            nickname: store.nickname,
            onDismiss: {
                store.send(.dismissTapped)
            },
            onSelectPopup: { popup in
                store.send(.popupSelected(popup))
            }
        )
        .accessibilityIdentifier("home_search")
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

private struct ComingPopupDetailDestinationView: View {
    let store: StoreOf<ComingPopupDetailDestinationFeature>

    var body: some View {
        ComingPopupDetailFeatureView(
            userUuid: store.userUuid,
            popups: store.popups,
            onSelectPopup: { userUuid, popup in
                store.send(.popupSelected(userUuid, popup))
            }
        )
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

private struct PopupRequestDestinationView: View {
    let store: StoreOf<PopupRequestDestinationFeature>

    var body: some View {
        PopupRequestFeatureView(
            userUuid: store.userUuid,
            onDismiss: {
                store.send(.dismissTapped)
            }
        )
    }
}

private struct PopupRequestManagementDestinationView: View {
    let store: StoreOf<PopupRequestManagementDestinationFeature>

    var body: some View {
        PopupRequestManagementFeatureView(
            onBack: {
                store.send(.backTapped)
            },
            onSelectSubmission: { submissionId in
                store.send(.submissionSelected(submissionId))
            }
        )
    }
}

private struct PopupRequestManagementDetailDestinationView: View {
    let store: StoreOf<PopupRequestManagementDetailDestinationFeature>

    var body: some View {
        PopupRequestManagementDetailFeatureView(
            submissionId: store.submissionId,
            onBack: {
                store.send(.backTapped)
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
