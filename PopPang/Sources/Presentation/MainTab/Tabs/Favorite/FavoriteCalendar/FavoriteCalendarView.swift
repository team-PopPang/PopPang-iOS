//
//  FavoriteCalendarView.swift
//  PopPang
//
//  Created by 김동현 on 10/18/25.
//

import SwiftUI

struct FavoriteCalendarView: View {
    @EnvironmentObject private var favoriteViewModel: FavoriteViewModel
    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: 0) {
                // MARK: - 캘린더
                CustomCalendar(
                    eventCounts: favoriteViewModel.popupEventCounts,
                    onDateSelected: { date in
                        favoriteViewModel.selectDate(date)
                    }
                )
                .padding(.top, 24)
                
                // MARK: - 시트
                ShadowDivider()
                    .ignoresSafeArea(edges: .horizontal)
                    .padding(.top, 20)
                
                PopupListView(
                    date: favoriteViewModel.selectedDate,
                    popups: favoriteViewModel.selectedPopups
                )
                
                Spacer()
            }
            .padding(.horizontal, 10)
        }
    }
}

#Preview {
    FavoriteCalendarView()
}
