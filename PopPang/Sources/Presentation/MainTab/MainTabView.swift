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
    @StateObject private var bookmarkViewModel: FavoriteViewModel
    
    init(userUduuid: String) {
        self.userUduuid = userUduuid
        
        // MARK: - 뷰모델초기화
        _homeViewModel = StateObject(wrappedValue: ViewModelFactory.shared.createHome(userUuid: userUduuid))
        _calendarViewModel = StateObject(wrappedValue: ViewModelFactory.shared.createCalendar(userUuid: userUduuid))
        _bookmarkViewModel = StateObject(wrappedValue: ViewModelFactory.shared.createBookmark(userUuid: userUduuid))
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
                        case .bookmark: FavoritekView()
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
        .environmentObject(bookmarkViewModel)
    }
}

#Preview {
    MainTabView(userUduuid: "1234")
}



