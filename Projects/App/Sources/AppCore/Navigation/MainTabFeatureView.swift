import AlertFeature
import CalendarFeature
import ComposableArchitecture
import Coordinator
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

struct MainTabFeatureHost: View {
    @State private var store: StoreOf<MainTabFeature>
    private let onLogout: @MainActor () -> Void

    init(
        session: MainTabSession,
        selectedTab: MainTab = .home,
        onLogout: @escaping @MainActor () -> Void
    ) {
        _store = State(
            initialValue: Store(
                initialState: MainTabFeature.State(
                    selectedTab: selectedTab,
                    session: session
                )
            ) {
                MainTabFeature()
            }
        )
        self.onLogout = onLogout
    }

    var body: some View {
        MainTabFeatureView(store: store, onLogout: onLogout)
    }
}

private struct MainTabFeatureView: View {
    @Bindable var store: StoreOf<MainTabFeature>
    let onLogout: @MainActor () -> Void

    var body: some View {
        NavigationStackStore(store.scope(state: \.path, action: \.path)) {
            TabView(selection: $store.selectedTab) {
                ForEach(MainTab.allCases, id: \.self) { tab in
                    tabView(for: tab)
                        .tabItem {
                            tab.tabAsset(selected: store.selectedTab == tab).swiftUIImage
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
        .fullScreenCover(item: $store.scope(\.search, action: \.search)) { store in
            SearchDestinationView(store: store)
        }
        .onChange(of: store.logoutToken) { _, value in
            guard value > 0 else { return }
            onLogout()
        }
    }

    @ViewBuilder
    private func tabView(for tab: MainTab) -> some View {
        switch tab {
        case .home:
            HomeFeatureView(
                userUuid: store.session.userUuid,
                nickname: store.session.nickname,
                isAdmin: store.session.isAdmin,
                onSelectPopup: { _, popup in
                    store.send(.homePopupSelected(popup))
                },
                onShowAlert: { _ in
                    store.send(.homeAlertTapped)
                },
                onSearch: { _ in
                    store.send(.homeSearchTapped)
                },
                onShowComingPopups: { _, popups in
                    store.send(.homeComingTapped(popups))
                },
                onReport: { _ in
                    store.send(.homeReportTapped)
                },
                onManagePopupRequests: {
                    store.send(.homeManagePopupRequestsTapped)
                }
            )
            .id(store.session)
        case .calendar:
            CalendarFeatureView(
                userUuid: store.session.userUuid,
                onShowAlert: { _ in
                    store.send(.calendarAlertTapped)
                },
                onSelectPopup: { _, popup in
                    store.send(.calendarPopupSelected(popup))
                }
            )
            .id(store.session)
        case .map:
            MapFeatureView(
                userUuid: store.session.userUuid,
                onSelectPopup: { _, popup in
                    store.send(.mapPopupSelected(popup))
                }
            )
            .id(store.session)
        case .favorites:
            FavoritesFeatureView(
                userUuid: store.session.userUuid,
                onShowAlert: { _ in
                    store.send(.favoritesAlertTapped)
                },
                onSelectPopup: { _, popup in
                    store.send(.favoritesPopupSelected(popup))
                },
                onBrowsePopups: {
                    store.send(.favoritesBrowsePopupsTapped)
                }
            )
            .id(store.session)
        case .profile:
            ProfileFeatureView(
                userUuid: store.session.userUuid,
                nickname: store.session.nickname,
                isAlerted: store.session.isAlerted,
                onShowAlert: { _ in
                    store.send(.profileAlertTapped)
                },
                onProfileSetting: { _, nickname, isAlerted in
                    store.send(.profileSettingTapped(nickname: nickname, isAlerted: isAlerted))
                },
                onNotification: {
                    store.send(.profileNotificationsTapped)
                },
                onServiceTerms: {
                    store.send(.profileServiceTermsTapped)
                }
            )
            .id(store.session)
        }
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
