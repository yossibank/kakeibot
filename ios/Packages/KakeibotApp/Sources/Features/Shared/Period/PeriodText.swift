import Core

enum PeriodText {
    static func range(_ period: ClosedRange<LocalDate>) -> String {
        "\(date(period.lowerBound))〜\(date(period.upperBound))"
    }

    static func startDay(_ startDay: MonthStartDay) -> String {
        startDay.isLastDay ? "毎月末日" : "毎月 \(startDay.day) 日"
    }
}

private extension PeriodText {
    static func date(_ date: LocalDate) -> String {
        "\(date.month)/\(date.day)"
    }
}
