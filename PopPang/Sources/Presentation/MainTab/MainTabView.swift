//
//  MainTabView.swift
//  PopPang
//
//  Created by 김동현 on 9/22/25.
//

import SwiftUI

struct MainTabView: View {
    @State private var selectedTab: MainTabType = .home
    
    init() {
        // 새로운 탭바 스타일(appearance) 인스턴스 생성
        let appearance = UITabBarAppearance()
        // 반투명 효과 제거, 불투명한 배경 설정, 상단 경계선 자동생성
        appearance.configureWithOpaqueBackground()
        // 상단 경계선 제거
        appearance.shadowColor = .clear
        // 탭바의 배경색 설정
        appearance.backgroundColor = Color.subWhite.uiColor
        
        // 경계선 대신 그림자 효과 추가
        UITabBar.appearance().layer.shadowColor = UIColor.black.cgColor
        UITabBar.appearance().layer.shadowOffset = CGSize(width: 0, height: -3)
        UITabBar.appearance().layer.shadowOpacity = 0.1
        UITabBar.appearance().layer.shadowRadius = 6
        
        // 선택되지 않은 아이템의 색상 (텍스트 & 이미지)
        appearance.stackedLayoutAppearance.normal.iconColor = UIColor.red
        appearance.stackedLayoutAppearance.normal.titleTextAttributes = [.foregroundColor: UIColor.gray]
        
        // 선택된 아이템 색상
        appearance.stackedLayoutAppearance.selected.iconColor = UIColor.black
        appearance.stackedLayoutAppearance.selected.titleTextAttributes = [.foregroundColor: UIColor.black]
        
        // 그림자 적용
        let image = UIImage.gradientImageWithBounds(
            bounds: CGRect( x: 0, y: 0, width: UIScreen.main.scale, height: 8),
            colors: [
                UIColor.clear.cgColor,
                UIColor.black.withAlphaComponent(0.07).cgColor
            ]
        )
        appearance.backgroundImage = UIImage()
        appearance.shadowImage = image
        
        // 폰트 적용
        let normalAttributes: [NSAttributedString.Key: Any] = [
            .foregroundColor: UIColor.gray,
            .font: UIFont.scdream(.light, size: 10)
        ]

        let selectedAttributes: [NSAttributedString.Key: Any] = [
            .foregroundColor: UIColor.black,
            .font: UIFont.scdream(.bold, size: 10)
        ]
        appearance.stackedLayoutAppearance.normal.titleTextAttributes = normalAttributes
        appearance.stackedLayoutAppearance.selected.titleTextAttributes = selectedAttributes

        // 일반상태(스크롤 안할 때)외형에 적용
        UITabBar.appearance().standardAppearance = appearance
        // 스크롤 edge에서의 탭바 외형에도 같은 appearance적용
        UITabBar.appearance().scrollEdgeAppearance = appearance
    }
    
    var body: some View {
        CoordinatorContainer {
            TabView(selection: $selectedTab) {
                ForEach(MainTabType.allCases, id: \.self) { tab in
                    Group {
                        switch tab {
                        case .home: HomeView()
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
    }
}

#Preview {
    MainTabView()
}



