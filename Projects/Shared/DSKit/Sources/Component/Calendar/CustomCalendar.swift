import SwiftUI

/// 월 달력. 선택 날짜는 화면 state가 가진 값을 받아서 그리고, 날짜를 누르거나 달을 넘기면 `onDateSelected`로 알린다.
/// 달력은 선택 날짜를 따로 들지 않는다. 그래서 달력이 다시 만들어져도 화면 state의 날짜와 어긋나지 않는다.
public struct CustomCalendar: View {
    let selectedDate: Date
    let eventCounts: [Date: Int]
    let onDateSelected: (Date) -> Void

    public init(
        selectedDate: Date,
        eventCounts: [Date: Int],
        onDateSelected: @escaping (Date) -> Void
    ) {
        self.selectedDate = selectedDate
        self.eventCounts = eventCounts
        self.onDateSelected = onDateSelected
    }

    public var body: some View {
        VStack(spacing: 0) {
            VStack {
                MonthHeaderView(
                    currentDate: selectedDate,
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
                    dates: Self.dates(inMonthOf: selectedDate),
                    currentDate: selectedDate,
                    eventCounts: eventCounts,
                    onSelect: select
                )
            }
            .padding(.horizontal, .contentPadding)
        }
    }

    /// 달을 넘겼을 때 선택할 날짜. 오늘 기준으로, 보이는 달에서 `value`만큼 옮긴 달의 오늘과 같은 날이다.
    /// 그 달에 같은 날이 없으면 그 달의 마지막 날이다(1/31 기준이면 2월은 28·29일, 3월은 다시 31일).
    public static func date(
        movingMonthOf selectedDate: Date,
        by value: Int,
        today: Date = Date(),
        calendar: Calendar = .current
    ) -> Date {
        let todayStart = calendar.startOfDay(for: today)
        guard
            let todayMonth = calendar.date(from: calendar.dateComponents([.year, .month], from: todayStart)),
            let selectedMonth = calendar.date(from: calendar.dateComponents([.year, .month], from: selectedDate))
        else { return todayStart }
        let offset = calendar.dateComponents([.month], from: todayMonth, to: selectedMonth).month ?? 0
        return calendar.date(byAdding: .month, value: offset + value, to: todayStart) ?? todayStart
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
            // 날짜 칸은 그릴 때마다 새로 만들므로, 칸의 위치로 구분해 같은 칸이 다시 생성되지 않게 한다.
            ForEach(Array(dates.enumerated()), id: \.offset) { _, value in
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
    /// 날짜를 누를 때와 달을 넘길 때 모두 이 함수로 선택을 알린다.
    func select(_ date: Date) {
        onDateSelected(date)
    }

    func moveMonth(by value: Int) {
        select(Self.date(movingMonthOf: selectedDate, by: value))
    }

    /// `date`가 속한 달의 날짜 칸. 첫 주의 앞쪽 빈칸은 `day == -1`로 채운다.
    static func dates(inMonthOf date: Date) -> [DateValue] {
        let calendar = Calendar.current
        var days = date.getAllDates().compactMap { date in
            DateValue(day: calendar.component(.day, from: date), date: date)
        }

        let firstWeekDay = calendar.component(.weekday, from: days.first?.date ?? date)

        for _ in 0 ..< firstWeekDay - 1 {
            days.insert(DateValue(day: -1, date: date), at: 0)
        }

        return days
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
