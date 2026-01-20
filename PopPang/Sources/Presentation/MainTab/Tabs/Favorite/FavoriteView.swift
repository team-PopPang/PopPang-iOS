//
//  BookmarkView.swift
//  PopPang
//
//  Created by 김동현 on 9/16/25.
//

import SwiftUI
import Kingfisher

struct FavoriteView: View {
    @EnvironmentObject private var coordinator: Coordinator<MainRoute, SheetRoute, OverlayRoute, FullScreenRoute>
    @EnvironmentObject private var rootViewModel: RootViewModel
    // @EnvironmentObject private var favoriteViewModel: FavoriteViewModel
    private let segments: [String] = ["찜리스트", "찜캘린더"]
    @Binding var selectedTab: MainTabType
    
    var body: some View {
        VStack(spacing: 0) {
            
            // MARK: - 네비게이션바            
            CustomNavigationBar {
                Text("찜")
                    .ppStyleFont(.scdream(.medium, size: 18))
                    .foregroundStyle(Color.mainBlack)
                    .frame(height: 45)
                
                Spacer()
                
                IconButton {
                    print("알림 버튼 클릭됨")
                    coordinator.push(.alert(uuid: rootViewModel.user?.userUuid ?? ""))
                }
            }
            
            // MARK: - 세그먼트
            SegmentedControlView(segments: segments,
                                 views: [
                                    FavoriteListView(selectedTab: $selectedTab),
                                    FavoriteCalendarView()
                                ],
                                 background: .mainGray3,
                                 foreground: .mainOrange
            )
            Spacer()
        }
    }
}

#Preview {
    @Previewable @State var selectedTab: MainTabType = .favorite
    NavigationStack {
        FavoriteView(selectedTab: $selectedTab)
            .environmentObject(Coordinator<MainRoute, SheetRoute, OverlayRoute, FullScreenRoute>())
            .environmentObject(RootViewModel())
            .environmentObject(FavoriteViewModel(userUuid: "1234"))
    }
}




