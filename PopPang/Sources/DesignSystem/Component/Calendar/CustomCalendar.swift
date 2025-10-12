//
//  CustomCalendar.swift
//  PopPang
//
//  Created by 김동현 on 10/11/25.
//

import SwiftUI
import Kingfisher

struct CustomCalendar: View {
    @StateObject private var viewModel: CustomCalendarViewModel
    
    init(popupList: [Popup]) {
        _viewModel = StateObject(wrappedValue: CustomCalendarViewModel(popupList: popupList))
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // MARK: - 캘린더
            VStack {
                MonthHeaderView(viewModel: viewModel)
                    .padding(.horizontal, 10)
                WeekHeaderView()
                    .padding(.top, 15)
                DateGridView(viewModel: viewModel)
                    .padding(.top, 15)
            }
            .padding(.horizontal, .contentPadding)
            
            // MARK: - 시트
            VStack(spacing: 0) {
                ShadowDivider()
                    .ignoresSafeArea(edges: .horizontal)
                
                PopupListView(date: viewModel.currentDate,
                              popups: viewModel.popupForDate(viewModel.currentDate))
                    .padding(.horizontal, .contentPadding)
            }
            .padding(.top, 15)
        }
    }
}

// MARK: - 월헤더
private struct MonthHeaderView: View {
    @ObservedObject var viewModel: CustomCalendarViewModel
    var body: some View {
        HStack {
            Button {
                viewModel.currentMonth -= 1
                viewModel.currentDate = viewModel.getCurrentMonth()
            } label: {
                Image(systemName: "chevron.left")
                    .font(.system(size: 20))
                    .foregroundStyle(Color.mainBlack)
            }
            
            Spacer()
            
            let parts = viewModel.extratYearAndMonth()
            HStack(spacing: 5) {
                Text("\(parts[0])년")
                Text(parts[1])
            }
            .ppStyleFont(.scdream(.medium, size: 15))
            
            Spacer()
            
            Button {
                viewModel.currentMonth += 1
                viewModel.currentDate = viewModel.getCurrentMonth()
            } label: {
                Image(systemName: "chevron.right")
                    .font(.system(size: 20))
                    .foregroundStyle(Color.mainBlack)
            }
        }
    }
}

// MARK: - 요일헤더
private struct WeekHeaderView: View {
    let days: [String] = ["일", "월", "화", "수", "목", "금", "토"]
    var body: some View {
        HStack(spacing: 0) {
            ForEach(days, id: \.self) { day in
                Text(day)
                    .ppStyleFont(.scdream(.medium, size: 10))
                    .frame(maxWidth: .infinity)
            }
        }
    }
}

// MARK: - 날짜 그리드
private struct DateGridView: View {
    @ObservedObject var viewModel: CustomCalendarViewModel
    
    let columns = Array(repeating: GridItem(.flexible()), count: 7)
    var body: some View {
        LazyVGrid(columns: columns, spacing: 15) {
            ForEach(viewModel.extractDate()) { value in
                DateCardView(viewModel: viewModel, value: value)
                    .onTapGesture {
                        viewModel.currentDate = value.date
                    }
            }
        }
    }
}

// MARK: - 날짜 카드
private struct DateCardView: View {
    @ObservedObject var viewModel: CustomCalendarViewModel
    var value: DateValue

    var body: some View {
        VStack(spacing: 5) {
            if value.day != -1 {
                ZStack {
                    Circle()
                        .fill(viewModel.isSameDay(date1: value.date,
                                                  date2: viewModel.currentDate)
                              ? Color.mainOrange    // 오늘 날짜
                              : Color.clear)
                        .frame(width: 28, height: 28)
                    
                    Text("\(value.day)")
                        .ppStyleFont(.scdream(.bold, size: 12))
                        .foregroundStyle(viewModel.isSameDay(date1: value.date,
                                                             date2: viewModel.currentDate)
                                         ? Color.mainWhite    // 오늘 날짜
                                         : Color.mainBlack)
                }
                
                let count = viewModel.popupCount(for: value.date)
                if count > 0 {
                    Text("+\(count)건")
                        .ppStyleFont(.scdream(.medium, size: 8))
                        .foregroundStyle(Color.mainOrange)
                        .frame(height: 10)
                } else {
                    Spacer()
                        .frame(height: 10)
                }
            }
        }
        .frame(height: 43)
    }
}

extension Date {
    
    /// 현재 월의 날짜를 Date 배열로 만들어준다
    /// - Returns: [Date]]
    func getAllDates() -> [Date] {
        let calendar = Calendar.current
        
        // 현재 월의 첫 날(startDate) 구하기 -> 일자를 지정하지 않고 year와 month만 구하기 때문에 그 해, 그 달의 첫날을 이렇게 구할 수 있다
        let startDate = calendar.date(from: Calendar.current.dateComponents([.year, .month], from: self))!
        
        // 현재 월의 일자 범위(날짜 수)(1...30 or 1...31)
        let range = calendar.range(of: .day, in: .month, for: startDate)!
        
        // range의 각각의 날짜(day)를 Date로 매핑해서 배열로 리턴
        return range.compactMap { day -> Date in
            // to: (현재 날짜, 일자)에 day를 더해서 새로운 날짜를 만든다
            return calendar.date(byAdding: .day, value: day - 1 , to: startDate)!
        }
    }
}


// MARK: - ViewModel
final class CustomCalendarViewModel: ObservableObject {
    
    // MARK: - 캘린더 헤더 날짜(2025년 10월)
    @Published var currentDate: Date = Date()
    
    // MARK: - 달력을 그릴 때 쓰는 기준 달(화살표 버튼 클릭 시 월 업데이트)
    @Published var currentMonth: Int = 0
    
    let popupList: [Popup]
    
    init(popupList: [Popup]) {
        self.popupList = popupList
    }
    
    /// 년도와 월 추출
    /// - Returns: [String]]
    func extratYearAndMonth() -> [String] {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "ko_KR")
        formatter.dateFormat = "yyyy MMMM"
        
        let date = formatter.string(from: currentDate)
        return date.components(separatedBy: " ")
    }
    
    /// 현재 캘린더에 보이는 Month 구하는 함수
    /// - Returns: Date
    func getCurrentMonth() -> Date {
        // 현재 날짜의 캘린더
        let calendar = Calendar.current
        
        // 현재 날짜의 month에 addingMonth의 month를 더해 새로운 month를 만든다
        // 만약 오늘이 1월 29일이고 currentMonth에 2를 더하면 3월 29일된다
        guard let currentMonth = calendar.date(byAdding: .month,
                                               value: self.currentMonth,
                                               to: Date()) else {
            return Date()
        }
        return currentMonth
    }
    
    /// 해당 월의 모든 날짜들을 DateValue 배열로 만들어주는 함수
    /// Grid로 보여주기 위함
    /// - Returns: [DateValue]]
    func extractDate() -> [DateValue] {
        // 현재 날짜의 캘린더
        let calendar = Calendar.current
        
        // 현재 월 구하기
        let currentMonth = getCurrentMonth()

        // 현재 월의 모든 날짜 구하기
        var days = currentMonth.getAllDates().compactMap { date -> DateValue in
            let day = calendar.component(.day, from: date)
            return DateValue(day: day, date: date)
        }
        
        // days로 구한 month의 가장 첫날이 시작되는 요일 구하기
        let firstWeekDay = calendar.component(.weekday, from: days.first?.date ?? Date())
        
        // month의 가장 첫날이 시작되는 요일 이전을 채워주는 과정
        // 만약 1월 1일이 수요일에 시작한다면 일~화요일까지 공백이므로  이부분을 공백으로 채워줘야 수요일부터 시작되는 캘린더 모양 생성
        // 만약 수요일(4)이 시작이라면 일(1)~화(3)까지 for-in문 순회해서 공백 추가
        // 캘린더 뷰에서 월의 첫 주를 올바르게 표시하기 위한 코드이다
        for _ in 0..<firstWeekDay-1 {
            // day: -1은 실제 날짜가 아닌 공백을 표시한 개념
            days.insert(DateValue(day: -1, date: Date()), at: 0)
        }
        
        return days
    }
    
    /// 두 날짜가 같은지 여부
    /// - Parameters:
    ///   - date1: 비교할 첫 번째 날짜
    ///   - date2: 비교할 두 번째 날짜
    /// - Returns: 같은 날이면 true 아니면 false
    func isSameDay(date1: Date, date2: Date) -> Bool {
        let calendar = Calendar.current
        return calendar.isDate(date1, inSameDayAs: date2)
    }
    
    /// 날짜가 기간 안에 포함되는지 확인하는 함수
    /// - Parameters:
    ///   - date: 검사할 대상 날짜
    ///   - start: 팝업 시작일
    ///   - end: 팝업 종료일
    /// - Returns: true이면 해당 날짜가 팝업 기간 내에 포함됨
    func isDate(_ date: Date, between start: Date, and end: Date) -> Bool {
        let calendar = Calendar.current
        let startDay = calendar.startOfDay(for: start)
        let endDay = calendar.startOfDay(for: end)
        let target = calendar.startOfDay(for: date)
        return target >= startDay && target <= endDay
    }
    
    /// 날짜별 팝업 개수 계산 함수
    /// 팝업A (13~15일)
    /// 팝업B (14~16일)
    /// popupCount: 13일: 1, 14일: 2, 15일: 2, 16일: 1
    /// - Parameter date: 팝업 개수를 계산할 대상 날짜
    /// - Returns: 해당 날짜에 진행중인 팝업 개수
    func popupCount(for date: Date) -> Int {
        popupList.filter { popup in
            isDate(date, between: popup.startDate, and: popup.endDate)
        }
        .count
    }
    
    /// 특정 날짜에 해당하는 팝업 리스트 반환
    /// - Parameter date: 선택된 날짜
    /// - Returns: 팝업 배열
    func popupForDate(_ date: Date) -> [Popup] {
        popupList.filter { popup in
            isDate(date, between: popup.startDate, and: popup.endDate)
        }
    }
}

private struct PopupListView: View {
    @EnvironmentObject private var coordinator: Coordinator<MainRoute, SheetRoute, OverlayRoute>
    let date: Date
    let popups: [Popup]
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            
            HStack {
                Text(formattedDate(date))
                    .ppStyleFont(.scdream(.bold, size: 15))
                Spacer()
            }
            .padding(.top, 10)
            
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
                .padding(.top, 24)
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
                    Text(popup.address.shortAddress)
                        .ppStyleFont(.scdream(.regular, size: 12))
                        .foregroundStyle(Color.mainBlack)
                    
                    Text(popup.name)
                        .ppStyleFont(.scdream(.medium, size: 15))
                        .foregroundStyle(Color.mainBlack)
                    
                    HStack {
                        Text(popup.startDate, formatter: DateFormatter.popupDateFormat)
                        Text("-")
                        Text(popup.endDate, formatter: DateFormatter.popupDateFormat)
                    }
                    .ppStyleFont(.scdream(.medium, size: 12))
                    .foregroundStyle(Color.mainGray)
                    
                    Spacer()
                }
                .padding(.leading, 18)
                .padding(.top, 10)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }
}


#Preview {
    @Previewable @State var currentDate = Date()
    CustomCalendar(popupList: [.popupMock, .popupMock, .popupMock])
}




