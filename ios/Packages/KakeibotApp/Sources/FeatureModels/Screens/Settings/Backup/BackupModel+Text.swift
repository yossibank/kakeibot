import Foundation

extension BackupModel {
    static func fileName(
        of kind: FileKind,
        at date: Date
    ) -> String {
        let day = text(
            of: date,
            format: "\(year: .defaultDigits)-\(month: .twoDigits)-\(day: .twoDigits)"
        )

        return "kakeibot-\(day).\(kind.rawValue)"
    }

    static func dayText(_ date: Date) -> String {
        text(
            of: date,
            format: "\(year: .defaultDigits)/\(month: .defaultDigits)/\(day: .defaultDigits)"
        )
    }

    static func dayTimeText(_ date: Date) -> String {
        let hour = Date.FormatStyle.Symbol.VerbatimHour.defaultDigits(
            clock: .twentyFourHour,
            hourCycle: .zeroBased
        )

        let time = text(of: date, format: "\(hour: hour):\(minute: .twoDigits)")

        return "\(dayText(date)) \(time)"
    }

    static func text(
        of date: Date,
        format: Date.FormatString
    ) -> String {
        let style = Date.VerbatimFormatStyle(
            format: format,
            timeZone: .current,
            calendar: Calendar(identifier: .gregorian)
        )

        return date.formatted(style)
    }
}
