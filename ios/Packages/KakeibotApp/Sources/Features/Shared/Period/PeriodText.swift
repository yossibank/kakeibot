import Core

enum PeriodText {
    static func range(_ period: ClosedRange<LocalDate>) -> String {
        "\(date(period.lowerBound))〜\(date(period.upperBound))"
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
        date.year == today.year ? self.date(date) : "\(date.year)/\(self.date(date))"
    }

    static func startDay(_ startDay: MonthStartDay) -> String {
        startDay.isLastDay ? "毎月末日" : "毎月 \(startDay.day) 日"
    }

    private static func date(_ date: LocalDate) -> String {
        "\(date.month)/\(date.day)"
    }
}
