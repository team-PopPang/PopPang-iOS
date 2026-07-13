import AlertFeature
import CalendarFeature
import ComposableArchitecture
import DSKit
import FavoritesFeature
import struct HomeFeature.HomeComingPopupDetailDestinationView
import struct HomeFeature.HomeFeatureView
import MapFeature
import PopupDetailFeature
import PopPangRNFeature
import ProfileFeature
import ReviewFeature
import SearchFeature
import SwiftUI

public struct MainTabFeatureView: View {
    @Bindable var store: StoreOf<MainTabFeature>

    public init(store: StoreOf<MainTabFeature>) {
        self.store = store
    }

    public var body: some View {
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
        .fullScreenCover(
            item: $store.scope(state: \.core.destination?.search, action: \.destination.search)
        ) { store in
            SearchDestinationView(store: store)
        }
        .fullScreenCover(
            item: $store.scope(state: \.core.destination?.popupRequest, action: \.destination.popupRequest)
        ) { store in
            PopPangRNFeatureView(store: store)
        }
    }

    @ViewBuilder
    private func tabView(for tab: MainTab) -> some View {
        switch tab {
        case .calendar:
            CalendarFeatureView(store: store.scope(state: \.core.calendar, action: \.calendar))
        case .home:
            HomeFeatureView(store: store.scope(state: \.core.home, action: \.home))
        case .map:
            MapFeatureView(store: store.scope(state: \.core.map, action: \.map))
        case .favorites:
            FavoritesFeatureView(store: store.scope(state: \.core.favorites, action: \.favorites))
        case .profile:
            ProfileFeatureView(store: store.scope(state: \.core.profile, action: \.profile))
        }
    }
}

private struct PopupDetailDestinationView: View {
    let store: StoreOf<PopupDetailDestinationFeature>

    var body: some View {
        PopupDetailFeatureView(
            store: store.scope(state: \.content, action: \.content),
            isAdmin: store.isAdmin,
            hidesSystemTabBar: store.hidesSystemTabBar,
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

private struct SearchDestinationView: View {
    @Bindable var store: StoreOf<SearchDestinationFeature>

    var body: some View {
        NavigationStack(path: $store.scope(state: \.path, action: \.path)) {
            SearchFeatureView(store: store.scope(state: \.search, action: \.search))
        } destination: { store in
            switch store.state {
            case .popupDetail:
                if let store = store.scope(state: \.popupDetail, action: \.popupDetail) {
                    PopupDetailDestinationView(store: store)
                }
            case .reviewDetail:
                if let store = store.scope(state: \.reviewDetail, action: \.reviewDetail) {
                    ReviewDetailDestinationView(store: store)
                }
            }
        }
    }
}

private struct PopupRequestManagementDestinationView: View {
    let store: StoreOf<PopPangRNFeature>

    var body: some View {
        PopPangRNFeatureView(store: store)
    }
}

private struct ReviewDetailDestinationView: View {
    let store: StoreOf<ReviewFeature>

    var body: some View {
        ReviewFeatureView(store: store)
    }
}

private struct AlertDestinationView: View {
    let store: StoreOf<AlertFeature>

    var body: some View {
        AlertFeatureView(store: store)
    }
}

private struct ProfileSettingDestinationView: View {
    let store: StoreOf<ProfileSettingFeature>

    var body: some View {
        ProfileSettingFeatureView(store: store)
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
