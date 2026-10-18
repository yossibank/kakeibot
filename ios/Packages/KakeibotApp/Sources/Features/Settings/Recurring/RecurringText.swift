import Core

enum RecurringText {}

extension RecurringText {
    static func schedule(
        _ frequency: Recurring.Frequency,
        month: Int,
        day: Int
    ) -> String {
        let dayText = day >= 31 ? "末日" : "\(day) 日"

        switch frequency {
        case .monthly: return "毎月 \(dayText)"
        case .yearly: return "毎年 \(month) 月 \(dayText)"
        }
    }

    static func remind(_ days: Int?) -> String {
        switch days {
        case nil: "知らせない"
        case 0: "当日"
        case 1: "前日"
        case let days?: "\(days) 日前"
        }
    }

    static func date(_ date: LocalDate) -> String {
        "\(date.year)/\(date.month)/\(date.day)"
    }
}
