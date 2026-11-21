import DSKit
import Foundation
import Testing

/// 달력에서 달을 넘길 때 선택할 날짜(`CustomCalendar.date(movingMonthOf:by:today:calendar:)`)를 확인한다.
/// 캘린더 탭과 찜캘린더는 이 날짜를 `dateSelected`로 받아 아래 목록도 같은 날짜로 바꾼다.
struct CustomCalendarMonthMoveTests {
    private let calendar: Calendar = {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(identifier: "Asia/Seoul")!
        return calendar
    }()

    private func date(_ year: Int, _ month: Int, _ day: Int, hour: Int = 0) -> Date {
        calendar.date(from: DateComponents(year: year, month: month, day: day, hour: hour))!
    }

    @Test("다른 날을 골랐어도 다음 달로 넘기면 오늘과 같은 날을 고른다")
    func nextMonthUsesTodaysDay() {
        let moved = CustomCalendar.date(
            movingMonthOf: date(2026, 11, 24),
            by: 1,
            today: date(2026, 11, 21, hour: 15),
            calendar: calendar
        )

        #expect(moved == date(2026, 12, 21))
    }

    @Test("이전 달로 넘기면 오늘보다 한 달 앞의 같은 날을 고른다")
    func previousMonthUsesTodaysDay() {
        let moved = CustomCalendar.date(
            movingMonthOf: date(2026, 11, 24),
            by: -1,
            today: date(2026, 11, 21),
            calendar: calendar
        )

        #expect(moved == date(2026, 10, 21))
    }

    @Test("다음 달에 갔다가 돌아오면 오늘을 고른다")
    func comingBackSelectsToday() {
        let today = date(2026, 11, 21, hour: 9)
        let next = CustomCalendar.date(movingMonthOf: today, by: 1, today: today, calendar: calendar)
        let back = CustomCalendar.date(movingMonthOf: next, by: -1, today: today, calendar: calendar)

        #expect(back == date(2026, 11, 21))
    }

    @Test("같은 날이 없는 달은 마지막 날을 고르고, 그다음 달은 다시 오늘과 같은 날을 고른다")
    func shortMonthFallsBackToLastDay() {
        let today = date(2026, 1, 31)
        let february = CustomCalendar.date(movingMonthOf: today, by: 1, today: today, calendar: calendar)
        let march = CustomCalendar.date(movingMonthOf: february, by: 1, today: today, calendar: calendar)

        #expect(february == date(2026, 2, 28))
        #expect(march == date(2026, 3, 31))
    }

    @Test("고른 날짜에는 시각을 남기지 않는다")
    func movedDateHasNoTime() {
        let moved = CustomCalendar.date(
            movingMonthOf: date(2026, 11, 21),
            by: 1,
            today: date(2026, 11, 21, hour: 23),
            calendar: calendar
        )

        #expect(moved == calendar.startOfDay(for: moved))
    }
}
