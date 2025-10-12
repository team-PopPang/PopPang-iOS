//
//  MainTabView.swift
//  PopPang
//
//  Created by 김동현 on 9/22/25.
//

import SwiftUI

struct MainTabView: View {
    @State private var selectedTab: MainTabType = .home
    @StateObject private var homeViewModel = ViewModelFactory.shared.createHome()
    @StateObject private var calendarViewModel = ViewModelFactory.shared.createCalendar()
    
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
                        case .bookmark: BookmarkView()
                        case .profile: ProfileView()
                        }
                    }
                    .tabItem {
                        Image(tab.tabImage(selected: selectedTab == tab))
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(width: 25, height: 25)
                        Text(tab.title)
                            // .font(selectedTab == tab ? Font.tapped : Font.normal)
                    }
                    .tag(tab)
                }
            }
        }
        .environmentObject(homeViewModel)
        .environmentObject(calendarViewModel)
    }
}

#Preview {
    MainTabView()
}



