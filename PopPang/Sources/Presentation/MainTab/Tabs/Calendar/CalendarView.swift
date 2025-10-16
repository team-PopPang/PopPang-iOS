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
    private let segments: [String] = ["월간", "주간"]
    
    var body: some View {
        VStack(spacing: 0) {
            
            // MARK: - 네비게이션바
            CustomNavigationBar {
                Text("캘린더")
                    .ppStyleFont(.scdream(.medium, size: 18))
                    .foregroundStyle(Color.mainBlack)
                
                Spacer()
                
                IconButton {
                    print("알림 버튼 클릭됨")
                    coordinator.push(.alert(uuid: rootViewModel.user?.userUuid ?? ""))
                }
            }
            
            // MARK: - 캘린더 & 시트
            ScrollView {
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
                    
                    PopupListView(
                        date: calendarViewModel.selectedDate,
                        popups: calendarViewModel.selectedPopups
                    )
                    
                    
                    Spacer()
                }
                .padding(.horizontal, 10)
                
            }
            .padding(.top, 10)
            Spacer()
        }
    }
}

#Preview {
    CalendarView()
        .environmentObject(Coordinator<MainRoute, SheetRoute, OverlayRoute>())
        .environmentObject(CalendarViewModel(userUuid: "1234"))
}


/*
private struct MonthlyCalendarView: View {
    @EnvironmentObject private var calendarViewModel: CalendarViewModel
    var body: some View {
        ScrollView {
            VStack {
                CustomCalendar(popupList: calendarViewModel.calendarPopups)
                    .padding(.top, 24)
                Spacer()
            }
            .padding(.horizontal, 10)
        }
    }
}

private struct WeeklyCalendarView: View {
    var body: some View {
        VStack {
            
        }
    }
}
 */


private struct PopupListView: View {
    @EnvironmentObject private var coordinator: Coordinator<MainRoute, SheetRoute, OverlayRoute>
    let date: Date
    let popups: [Popup]
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            
            HStack {
                Text(formattedDate(date))
                    .ppStyleFont(.scdream(.bold, size: 12))
                    .foregroundStyle(Color.mainBlack)
                Spacer()
            }
            .padding(.top, 20)
            
            if popups.isEmpty {
                Text("선택한 날짜에 팝업이 없습니다")
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding(.top, 24)
            } else {
                ScrollView(showsIndicators: false) {
                    VStack(spacing: 10) {
                        ForEach(Array(popups.enumerated()), id: \.element) { index, popup in
                            CalendarPopupCell(popup: popup)
                                .onTapGesture {
                                    coordinator.push(.popupDetail(popup))
                                }
                            
                            // 마미막 셀 아래에는 Divider 넣지 않겠다
                            if index != popups.count - 1 {
                                Divider()
                                    .frame(height: 1)
                                    .background(Color.subWhite)
                            }
                        }
                    }
                }
                .padding(.top, 20)
            }
        }
    }
    
    private func formattedDate(_ date: Date) -> String {
        let dayFormatter = DateFormatter()
        dayFormatter.locale = Locale(identifier: "ko_KR")
        dayFormatter.dateFormat = "d일 (E)"
        return dayFormatter.string(from: date)
    }
}

private struct CalendarPopupCell: View {
    let popup: Popup
    
    var body: some View {
        VStack(spacing: 0) {
            HStack(spacing: 0) {
                KFImage(URL(string: popup.imageURL))
                    .placeholder {
                        Rectangle()
                            .fill(Color.mainGray3)
                            .frame(width: 106, height: 133)
                    }
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(width: 106, height: 133, alignment: .center)
                    .clipped()
                
                VStack(alignment: .leading, spacing: 0) {
                    Text(popup.roadAddress?.shortAddress ?? popup.address.shortAddress)
                        .font(.scdream(.regular, size: 12))
                        .foregroundStyle(Color.mainBlack)
                    
                    Text(popup.name)
                        .font(.scdream(.bold, size: 15))
                        .foregroundStyle(Color.mainBlack)
                        .lineLimit(1) // 한줄만 표시
                        .truncationMode(.tail) // 넘치면 ...으로 표시
                        .padding(.top, 5)
                  
                    HStack {
                        Text(popup.startDate, formatter: DateFormatter.popupDateFormat)
                        Text("-")
                        Text(popup.endDate, formatter: DateFormatter.popupDateFormat)
                    }
                    .font(.scdream(.regular, size: 12))
                    .foregroundStyle(Color.mainGray)
                    .padding(.top, 5)
                    .padding(.leading, -1)
                    
                    Spacer()
                }
                .padding(.leading, 18)
                .padding(.top, 10)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }
}
