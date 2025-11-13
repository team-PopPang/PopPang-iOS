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
                .padding(.horizontal, 15)
                
                // MARK: - 시트
                FavoriteCalendarPopupListView(
                    date: favoriteViewModel.selectedDate,
                    popups: favoriteViewModel.selectedPopups
                )
                .padding(.horizontal, 15)
                
                // MARK: - 그림자 시트 디자인
                .background(
                    RoundedRectangle(cornerRadius: 15)
                        .fill(Color.white)
                        .mask(
                            // 위쪽 70%만 유지시키고 아래 30%는 잘라버림
                            LinearGradient(
                                gradient: Gradient(colors: [.black, .clear, .clear, .clear]),
                                startPoint: .top,
                                endPoint: .bottom
                            )
                        )
                        .applyShadow(
                            color: .black,
                            alpha: 0.05,
                            x: 0,
                            y: -4,
                            blur: 8
                        )
                )
                .padding(.top, 20)
                
                Spacer()
            }
        }
        .onAppear {
            Task {
                await favoriteViewModel.getFavoritePopups()
            }
        }
    }
}

#Preview {
    FavoriteCalendarView()
        .environmentObject(FavoriteViewModel(userUuid: "1234"))
}
