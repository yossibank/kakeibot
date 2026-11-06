import Core

enum PeriodText {
    static func range(_ period: ClosedRange<LocalDate>) -> String {
        "\(period.lowerBound.monthDayText)〜\(period.upperBound.monthDayText)"
    }

    static func range(
        _ period: ClosedRange<LocalDate>,
        today: LocalDate
    ) -> String {
        "\(day(period.lowerBound, today: today))〜\(day(period.upperBound, today: today))"
    }

    static func day(
        _ date: LocalDate,
        today: LocalDate
    ) -> String {
        date.year == today.year ? date.monthDayText : "\(date.year)/\(date.monthDayText)"
    }

    static func startDay(_ startDay: MonthStartDay) -> String {
        let day = startDay.isLastDay ? "毎月末日" : "毎月 \(startDay.day) 日"
        return startDay.shift == .none ? day : "\(day)・\(startDay.shift.title)"
    }

    static func weekdayDate(_ date: LocalDate) -> String {
        "\(date.monthDayText)（\(date.weekday.shortName)）"
    }
}
