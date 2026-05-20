import SwiftUI

public struct CustomCalendar: View {
    @StateObject private var viewModel = CustomCalendarViewModel()
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
                MonthHeaderView(viewModel: viewModel)
                    .padding(.horizontal, 10)
                WeekHeaderView()
                    .padding(.top, 20)
                DateGridView(
                    viewModel: viewModel,
                    eventCounts: eventCounts,
                    onSelect: onDateSelected
                )
            }
            .padding(.horizontal, .contentPadding)
        }
    }
}

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

            let parts = viewModel.extractYearAndMonth()
            HStack(spacing: 5) {
                Text("\(parts[0])년")
                Text(parts[1])
            }
            .ppStyleFont(.scdream(.medium, size: 17))
            .foregroundStyle(Color.mainBlack)

            Spacer()

            Button {
                viewModel.moveMonth(by: 1)
            } label: {
                Image(systemName: "chevron.right")
                    .font(.system(size: 20))
                    .foregroundStyle(Color.mainBlack)
            }
        }
    }
}

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

private struct DateGridView: View {
    @ObservedObject var viewModel: CustomCalendarViewModel
    let eventCounts: [Date: Int]
    let onSelect: (Date) -> Void

    let columns = Array(repeating: GridItem(.flexible()), count: 7)

    var body: some View {
        LazyVGrid(columns: columns, spacing: 15) {
            ForEach(viewModel.dates) { value in
                let isSelected = viewModel.isSameDay(date1: value.date, date2: viewModel.currentDate)
                let eventCount = eventCounts[value.date.stripTime()] ?? 0

                DateCardView(
                    day: value.day,
                    isSelected: isSelected,
                    eventCount: eventCount
                ) {
                    viewModel.currentDate = value.date
                    if value.day != -1 {
                        onSelect(value.date)
                    }
                }
            }
        }
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
                    Text("+\(eventCount)건")
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

final class CustomCalendarViewModel: ObservableObject {
    @Published private(set) var dates: [DateValue] = []
    @Published var currentDate: Date = .init()
    @Published var currentMonth: Int = 0

    init() {
        extractDate()
    }

    func extractYearAndMonth() -> [String] {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "ko_KR")
        formatter.dateFormat = "yyyy MMMM"
        return formatter.string(from: currentDate).components(separatedBy: " ")
    }

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

    func isSameDay(date1: Date, date2: Date) -> Bool {
        Calendar.current.isDate(date1, inSameDayAs: date2)
    }

    func moveMonth(by value: Int) {
        currentMonth += value
        currentDate = getCurrentMonth()
        extractDate()
    }
}
