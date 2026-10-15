import SwiftUI

public struct CustomCalendar: View {
    @State private var dates: [DateValue] = []
    @State private var currentDate: Date = .init()
    @State private var currentMonth: Int = 0

    let eventCounts: [Date: Int]
    let onDateSelected: (Date) -> Void

    public init(
        eventCounts: [Date: Int],
        onDateSelected: @escaping (Date) -> Void
    ) {
        self.eventCounts = eventCounts
        self.onDateSelected = onDateSelected
    }

    public var body: some View {
        VStack(spacing: 0) {
            VStack {
                MonthHeaderView(
                    currentDate: currentDate,
                    onPreviousTapped: {
                        moveMonth(by: -1)
                    },
                    onNextTapped: {
                        moveMonth(by: 1)
                    }
                )
                    .padding(.horizontal, 10)
                WeekHeaderView()
                    .padding(.top, 20)
                DateGridView(
                    dates: dates,
                    currentDate: currentDate,
                    eventCounts: eventCounts,
                    onSelect: { date in
                        currentDate = date
                        onDateSelected(date)
                    }
                )
            }
            .padding(.horizontal, .contentPadding)
        }
        .onAppear {
            extractDate()
        }
    }
}

private struct MonthHeaderView: View {
    let currentDate: Date
    let onPreviousTapped: () -> Void
    let onNextTapped: () -> Void

    var body: some View {
        HStack {
            Button {
                onPreviousTapped()
            } label: {
                Image(systemName: "chevron.left")
                    .font(.system(size: 20))
                    .foregroundStyle(Color.mainBlack)
            }

            Spacer()

            Text(yearMonthTitle())
                .ppStyleFont(.scdream(.medium, size: 17))
                .foregroundStyle(Color.mainBlack)

            Spacer()

            Button {
                onNextTapped()
            } label: {
                Image(systemName: "chevron.right")
                    .font(.system(size: 20))
                    .foregroundStyle(Color.mainBlack)
            }
        }
    }

    /// 화면 문구와 같은 언어로 연월을 쓴다. 예: 2026년 10월, October 2026, 2026年10月
    private func yearMonthTitle() -> String {
        let formatter = DateFormatter()
        formatter.locale = .displayLanguage
        formatter.calendar = Calendar(identifier: .gregorian)
        formatter.setLocalizedDateFormatFromTemplate("yyyyMMMM")
        return formatter.string(from: currentDate)
    }
}

private struct WeekHeaderView: View {
    /// 일요일부터 시작하는 짧은 요일 이름. 화면 문구와 같은 언어로 쓴다. 예: 일, Sun, 日
    let days: [String] = {
        var calendar = Calendar(identifier: .gregorian)
        calendar.locale = .displayLanguage
        return calendar.shortWeekdaySymbols
    }()

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

private struct DateGridView: View {
    let dates: [DateValue]
    let currentDate: Date
    let eventCounts: [Date: Int]
    let onSelect: (Date) -> Void

    let columns = Array(repeating: GridItem(.flexible()), count: 7)

    var body: some View {
        LazyVGrid(columns: columns, spacing: 15) {
            ForEach(dates) { value in
                let isSelected = Calendar.current.isDate(value.date, inSameDayAs: currentDate)
                let eventCount = eventCounts[value.date.stripTime()] ?? 0

                DateCardView(
                    day: value.day,
                    isSelected: isSelected,
                    eventCount: eventCount
                ) {
                    if value.day != -1 {
                        onSelect(value.date)
                    }
                }
            }
        }
    }
}

private extension CustomCalendar {
    func getCurrentMonth() -> Date {
        let calendar = Calendar.current
        return calendar.date(byAdding: .month, value: currentMonth, to: Date()) ?? Date()
    }

    func extractDate() {
        let calendar = Calendar.current
        let currentMonth = getCurrentMonth()

        var days = currentMonth.getAllDates().compactMap { date in
            let day = calendar.component(.day, from: date)
            return DateValue(day: day, date: date)
        }

        let firstWeekDay = calendar.component(.weekday, from: days.first?.date ?? Date())

        for _ in 0 ..< firstWeekDay - 1 {
            days.insert(DateValue(day: -1, date: Date()), at: 0)
        }

        dates = days
    }

    func moveMonth(by value: Int) {
        currentMonth += value
        currentDate = getCurrentMonth()
        extractDate()
    }
}

private struct DateCardView: View {
    let day: Int
    let isSelected: Bool
    let eventCount: Int
    let onTapped: (() -> Void)?

    var body: some View {
        VStack(spacing: 5) {
            if day != -1 {
                ZStack {
                    Circle()
                        .fill(isSelected ? Color.mainOrange : Color.clear)
                        .frame(width: 28, height: 28)

                    Text("\(day)")
                        .ppStyleFont(.scdream(.bold, size: 12))
                        .foregroundStyle(isSelected ? Color.mainWhite : Color.mainBlack)
                }

                if eventCount > 0 {
                    Text("+\(eventCount)건", bundle: .module)
                        .ppStyleFont(.scdream(.medium, size: 8))
                        .foregroundStyle(Color.mainOrange)
                        .frame(height: 10)
                } else {
                    Spacer()
                        .frame(height: 10)
                }

                Spacer()
                    .frame(height: 10)
            }
        }
        .frame(height: 43)
        .onTapGesture {
            onTapped?()
        }
    }
}

extension Date {
    func getAllDates() -> [Date] {
        let calendar = Calendar.current
        let startDate = calendar.date(
            from: Calendar.current.dateComponents([.year, .month], from: self)
        )!
        let range = calendar.range(of: .day, in: .month, for: startDate)!

        return range.compactMap { day in
            calendar.date(byAdding: .day, value: day - 1, to: startDate)!
        }
    }

    func stripTime() -> Date {
        Calendar.current.startOfDay(for: self)
    }
}

private extension Locale {
    /// DSKit 번들이 문구를 보여 주는 언어. 기기 지역과 앱 언어가 달라도 날짜가 문구와 같은 언어로 나온다.
    static var displayLanguage: Locale {
        Locale(identifier: Bundle.module.preferredLocalizations.first ?? "ko")
    }
}
