//
//  CalendarView.swift
//  PopPang
//
//  Created by 김동현 on 9/16/25.
//

import SwiftUI
import Kingfisher

struct CalendarView: View {
    @EnvironmentObject private var coordinator: Coordinator<MainRoute, SheetRoute, OverlayRoute>
    @EnvironmentObject private var calendarViewModel: CalendarViewModel
    @EnvironmentObject private var rootViewModel: RootViewModel
    
    var body: some View {
        VStack(spacing: 0) {
            
            // MARK: - 네비게이션바
            CustomNavigationBar {
                Text("캘린더")
                    .ppStyleFont(.scdream(.medium, size: 18))
                    .foregroundStyle(Color.mainBlack)
                
                Spacer()
                
                IconButton {
                    coordinator.push(.alert(uuid: rootViewModel.user?.userUuid ?? ""))
                }
            }
            
            // MARK: - 캘린더 & 시트
            ScrollView(showsIndicators: false) {
                VStack(spacing: 0) {
                    
                    // MARK: - 캘린더
                    CustomCalendar(
                        eventCounts: calendarViewModel.popupEventCounts,
                        onDateSelected: { date in
                            calendarViewModel.selectDate(date)
                        }
                    )
                    .padding(.top, 24)
                    
                    // MARK: - 시트
                    ShadowDivider()
                        .ignoresSafeArea(edges: .horizontal)
                        .padding(.top, 20)
                    
                    CalendarPopupListView(
                        userUuid: calendarViewModel.userUuid,
                        date: calendarViewModel.selectedDate,
                        popups: calendarViewModel.selectedPopups
                    )
                    
                    Spacer()
                }
                .padding(.horizontal, 15)
                
            }
            .padding(.top, 10)
            Spacer()
        }
        .onAppear {
            Task {
                await calendarViewModel.getAllPopupData()
            }
        }
    }
}

#Preview {
    CalendarView()
        .environmentObject(Coordinator<MainRoute, SheetRoute, OverlayRoute>())
        .environmentObject(CalendarViewModel(userUuid: "1234"))
}
