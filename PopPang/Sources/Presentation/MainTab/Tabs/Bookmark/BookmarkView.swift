//
//  BookmarkView.swift
//  PopPang
//
//  Created by 김동현 on 9/16/25.
//

import SwiftUI

struct BookmarkView: View {
    @EnvironmentObject private var coordinator: Coordinator<MainRoute, SheetRoute, OverlayRoute>
    @EnvironmentObject private var rootViewModel: RootViewModel
    private let segments: [String] = ["리스트", "캘린더"]
    
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
                                    ListView(),
                                    FavoriteCalendarView()
                                ],
                                 background: .mainGray3,
                                 foreground: .mainOrange,
            )
            Spacer()
        }
    }
}

#Preview {
    NavigationStack {
        BookmarkView()
    }
}

struct ListView: View {
    var body: some View {
        VStack {
            Text("ListView")
        }
    }
}

struct FavoriteCalendarView: View {
    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: 0) {
                // MARK: - 캘린더
                CustomCalendar(eventCounts: [:], onDateSelected: { date in
                    
                })
                .padding(.top, 24)
                
                // MARK: - 시트
                ShadowDivider()
                    .ignoresSafeArea(edges: .horizontal)
                
                PopupListView(
                    date: .now,
                    popups: []
                )
                
                Spacer()
            }
            .padding(.horizontal, 10)
        }
    }
}
