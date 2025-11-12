//
//  MainTabView.swift
//  PopPang
//
//  Created by 김동현 on 9/22/25.
//

import SwiftUI

struct MainTabView: View {
    var userUuid: String
    var isAlerted: Bool
    
    @State private var selectedTab: MainTabType = .home
    @EnvironmentObject private var rootViewModel: RootViewModel
    @StateObject private var homeViewModel: HomeViewModel
    @StateObject private var calendarViewModel: CalendarViewModel
    @StateObject private var mapViewModel: MapViewModel
    @StateObject private var favoriteViewModel: FavoriteViewModel
    @StateObject private var profileViewModel: ProfileViewModel
    
    
    init(userUuid: String, isAlerted: Bool) {
        self.userUuid = userUuid
        self.isAlerted = isAlerted
        
        // MARK: - 뷰모델초기화
        _homeViewModel = StateObject(wrappedValue: ViewModelFactory.shared.createHome(userUuid: userUuid))
        _calendarViewModel = StateObject(wrappedValue: ViewModelFactory.shared.createCalendar(userUuid: userUuid))
        _mapViewModel = StateObject(wrappedValue: ViewModelFactory.shared.createMapViewModel(userUuid: userUuid))
        _favoriteViewModel = StateObject(wrappedValue: ViewModelFactory.shared.createBookmark(userUuid: userUuid))
        _profileViewModel = StateObject(wrappedValue: ViewModelFactory.shared.createProfile(userUuid: userUuid, isAlerted: isAlerted))
    }
    
    var body: some View {
        CoordinatorContainer {
            TabView(selection: $selectedTab) {
                ForEach(MainTabType.allCases, id: \.self) { tab in
                    Group {
                        switch tab {
                        case .home:     HomeView()
                        case .calendar: CalendarView()
                        case .map:      MapView()
                        case .favorite: FavoriteView(selectedTab: $selectedTab)
                        case .profile:  ProfileView()
                        }
                    }
                    .tabItem {
                        Image(tab.tabImage(selected: selectedTab == tab))
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(width: 25, height: 25)
                        Text(tab.title)
                    }
                    .tag(tab)
                }
            }
        }
        .environmentObject(homeViewModel)
        .environmentObject(calendarViewModel)
        .environmentObject(mapViewModel)
        .environmentObject(favoriteViewModel)
        .environmentObject(profileViewModel)
    }
}

#Preview {
    MainTabView(userUuid: "1234", isAlerted: false)
        .environmentObject(RootViewModel())
        .environmentObject(HomeViewModel(userUuid: "1234"))
        .environmentObject(CalendarViewModel(userUuid: "1234"))
        .environmentObject(MapViewModel(userUuid: "1234"))
        .environmentObject(FavoriteViewModel(userUuid: "1234"))
        .environmentObject(ProfileViewModel(userUuid: "1234", isAlerted: false))
}



