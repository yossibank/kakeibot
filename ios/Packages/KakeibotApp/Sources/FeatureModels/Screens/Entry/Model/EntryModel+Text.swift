import Core
import DesignSystem
import Foundation

public extension EntryModel {
    struct NoteLine: Equatable {
        public let title: String
        public let value: String
    }
}

public extension EntryModel {
    static func dateText(
        for date: LocalDate,
        today: LocalDate
    ) -> String {
        let text = weekdayText(for: date, today: today)

        switch date {
        case today: return "今日 \(text)"
        case today.adding(days: -1): return "昨日 \(text)"
        default: return text
        }
    }

    static func keypadDateText(
        for date: LocalDate,
        today: LocalDate
    ) -> String {
        date == today ? "今日" : weekdayText(for: date, today: today)
    }

    static func shortDateText(
        for date: LocalDate,
        today: LocalDate
    ) -> String {
        switch date {
        case today: "今日"
        case today.adding(days: -1): "昨日"
        default: PeriodText.day(date, today: today)
        }
    }

    static func dateTitle(
        for date: LocalDate,
        today: LocalDate
    ) -> String {
        let days = date.days(until: today)

        switch days {
        case 0, 1: return "日付"
        case 2...: return "日付・\(days)日前"
        default: return "日付・\(-days)日後"
        }
    }
}

private extension EntryModel {
    static func weekdayText(
        for date: LocalDate,
        today: LocalDate
    ) -> String {
        "\(PeriodText.day(date, today: today))（\(date.weekday.shortName)）"
    }
}
