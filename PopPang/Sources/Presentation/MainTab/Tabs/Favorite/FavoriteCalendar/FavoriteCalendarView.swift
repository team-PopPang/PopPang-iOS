//
//  FavoriteCalendarView.swift
//  PopPang
//
//  Created by 김동현 on 10/18/25.
//

import SwiftUI

struct FavoriteCalendarView: View {
    @EnvironmentObject private var bookmarkViewModel: BookmarkViewModel
    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: 0) {
                // MARK: - 캘린더
                CustomCalendar(
                    eventCounts: bookmarkViewModel.popupEventCounts,
                    onDateSelected: { date in
                        bookmarkViewModel.selectDate(date)
                    }
                )
                .padding(.top, 24)
                
                // MARK: - 시트
                ShadowDivider()
                    .ignoresSafeArea(edges: .horizontal)
                
                PopupListView(
                    date: bookmarkViewModel.selectedDate,
                    popups: bookmarkViewModel.selectedPopups
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
