//
//  MainTabView.swift
//  PopPang
//
//  Created by 김동현 on 9/22/25.
//

import SwiftUI

struct MainTabView: View {
    var userUduuid: String
    @State private var selectedTab: MainTabType = .home
    @EnvironmentObject private var rootViewModel: RootViewModel
    @StateObject private var homeViewModel: HomeViewModel
    @StateObject private var calendarViewModel: CalendarViewModel
    @StateObject private var favoriteViewModel: FavoriteViewModel
    @StateObject private var profileViewModel: ProfileViewModel
    
    init(userUduuid: String) {
        self.userUduuid = userUduuid
        
        // MARK: - 뷰모델초기화
        _homeViewModel = StateObject(wrappedValue: ViewModelFactory.shared.createHome(userUuid: userUduuid))
        _calendarViewModel = StateObject(wrappedValue: ViewModelFactory.shared.createCalendar(userUuid: userUduuid))
        _favoriteViewModel = StateObject(wrappedValue: ViewModelFactory.shared.createBookmark(userUuid: userUduuid))
        _profileViewModel = StateObject(wrappedValue: ViewModelFactory.shared.createProfile(userUuid: userUduuid))
    }
    
    var body: some View {
        CoordinatorContainer {
            TabView(selection: $selectedTab) {
                ForEach(MainTabType.allCases, id: \.self) { tab in
                    Group {
                        switch tab {
                        case .home:
                            HomeView()
                        case .calendar: CalendarView()
                        case .map: MapView()
                        case .favorite: FavoriteView(selectedTab: $selectedTab)
                        case .profile: ProfileView()
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
        .environmentObject(favoriteViewModel)
        .environmentObject(profileViewModel)
    }
}

#Preview {
    MainTabView(userUduuid: "1234")
        .environmentObject(RootViewModel())
        .environmentObject(HomeViewModel(userUuid: "1234"))
        .environmentObject(CalendarViewModel(userUuid: "1234"))
        .environmentObject(FavoriteViewModel(userUuid: "1234"))
        .environmentObject(ProfileViewModel(userUuid: "1234"))
}



