//
//  CustomCalendar.swift
//  PopPang
//
//  Created by 김동현 on 10/11/25.
//

import SwiftUI
import Kingfisher
import AutoEquatable

struct CustomCalendar: View {
    @StateObject private var viewModel = CustomCalendarViewModel()
    let eventCounts: [Date: Int]
    let onDateSelected: (Date) -> Void
    
    init(eventCounts: [Date: Int],
         onDateSelected: @escaping (Date) -> Void) {
        self.eventCounts = eventCounts
        self.onDateSelected = onDateSelected
    }
    var body: some View {
        VStack(spacing: 0) {
            // MARK: - 캘린더
            VStack {
                MonthHeaderView(viewModel: viewModel)
                    .padding(.horizontal, 10)
                WeekHeaderView()
                    .padding(.top, 20)
                DateGridView(
                    viewModel: viewModel,
                    eventCounts: eventCounts,
                    onSelect: onDateSelected
                )
                .padding(.top, 0)
            }
            .padding(.horizontal, .contentPadding)
        }
    }
}

// MARK: - 월헤더
private struct MonthHeaderView: View {
    @ObservedObject var viewModel: CustomCalendarViewModel
    var body: some View {
        HStack {
            Button {
                viewModel.moveMonth(by: -1)
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
            .ppStyleFont(.scdream(.medium, size: 17))
            .foregroundStyle(Color.mainBlack)
            
            Spacer()
            
            Button {
                viewModel.moveMonth(by: +1)
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
                    .ppStyleFont(.scdream(.regular, size: 12))
                    .foregroundStyle(Color.mainGray2)
                    .frame(maxWidth: .infinity)
            }
        }
    }
}

// MARK: - 날짜 그리드
private struct DateGridView: View {
    @ObservedObject var viewModel: CustomCalendarViewModel
    let eventCounts: [Date: Int]
    let onSelect: (Date) -> Void
    
    let columns = Array(repeating: GridItem(.flexible()), count: 7)
    var body: some View {
        LazyVGrid(columns: columns, spacing: 15) {
            ForEach(viewModel.dates, id: \.id) { value in
                
                let isSelected = viewModel.isSameDay(date1: value.date, date2: viewModel.currentDate)
                let eventCount = eventCounts[value.date.stripTime()] ?? 0
                DateCardView(day: value.day,
                             isSelected: isSelected,
                             eventCount: eventCount) {
                    viewModel.currentDate = value.date
                    if value.day != -1 {
                        onSelect(value.date)   // 날짜 클릭 시 콜백 전달
                    }
                }
                .equatable()
            }
        }
    }
}

// MARK: - 날짜 카드
@AutoEquatable
private struct DateCardView: View {

    let day: Int
    let isSelected: Bool
    let eventCount: Int
    
    @AutoIgnored
    let onTapped: (() -> Void)?

    var body: some View {
        VStack(spacing: 5) {
            if day != -1 {
                ZStack {
                    Circle()
                        .fill(isSelected
                              ? Color.mainOrange    // 오늘 날짜
                              : Color.clear)
                        .frame(width: 28, height: 28)
                    
                    Text("\(day)")
                        .ppStyleFont(.scdream(.bold, size: 12))
                        .foregroundStyle(isSelected
                                         ? Color.mainWhite    // 오늘 날짜
                                         : Color.mainBlack)
                }
                

                if eventCount > 0 {
                    Text("+\(eventCount)건")
                        .ppStyleFont(.scdream(.medium, size: 8))
                        .foregroundStyle(Color.mainOrange)
                        .frame(height: 10)
                } else {
                    Spacer()
                        .frame(height: 10)
                }

                Spacer().frame(height: 10)
            }
        }
        .frame(height: 43)
        .onTapGesture { onTapped?() }
        // .debugBodyRandomBackground()
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
    
    
    /// 날짜(Date)에서 시간(Hour, Minute, Second)을 잘라내고 “0시 0분 0초”로 만든다
    /// - Returns: 2025-10-16 00:00:00
    func stripTime() -> Date {
        Calendar.current.startOfDay(for: self)
    }
}


// MARK: - ViewModel
final class CustomCalendarViewModel: ObservableObject {
    
    // MARK: - 캘린더에 그릴 날짜 배열(월 변경시에마 바뀜)
    @Published private(set) var dates: [DateValue] = []
    
    // MARK: - 캘린더 헤더 날짜(2025년 10월)
    @Published var currentDate: Date = Date()
    
    // MARK: - 달력을 그릴 때 쓰는 기준 달(화살표 버튼 클릭 시 월 업데이트)
    @Published var currentMonth: Int = 0
    
    init() {
        extractDate()
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
    func extractDate() {
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
        
        self.dates = days
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
    
    func moveMonth(by offset: Int) {
        self.currentMonth += offset
        currentDate = getCurrentMonth()
        extractDate()
    }
}

//#Preview {
//    @Previewable @State var currentDate = Date()
//    CustomCalendar(popupList: [.popupMock, .popupMock, .popupMock])
//}


