//
//  FavoriteCalendarView.swift
//  PopPang
//
//  Created by 김동현 on 10/18/25.
//

import SwiftUI

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

#Preview {
    FavoriteCalendarView()
}
