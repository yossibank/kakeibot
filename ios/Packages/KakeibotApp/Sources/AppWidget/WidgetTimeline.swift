import Foundation

enum WidgetTimeline {
    static let retryInterval: TimeInterval = 30 * 60

    static func nextMidnight(after date: Date) -> Date? {
        let calendar = Calendar.current
        let start = calendar.startOfDay(for: date)

        return calendar.date(byAdding: .day, value: 1, to: start)
    }
}
