import Core
import Store

extension ReviewModel {
    struct Cache {
        enum Source {
            case list
            case today
            case kind
            case noSpendDays
            case recurrings
        }

        var summaries: [ClosedRange<LocalDate>: ReviewSummary] = [:]
        var moves: [ClosedRange<LocalDate>: [Move]] = [:]
        var upcoming: [ClosedRange<LocalDate>: Int] = [:]
        var closing: [ClosingKey: ReviewClosingView.Content] = [:]

        mutating func invalidate(_ source: Source) {
            switch source {
            case .list:
                self = Cache()

            case .today:
                moves = [:]
                upcoming = [:]
                closing = [:]

            case .kind:
                upcoming = [:]

            case .noSpendDays:
                closing = [:]

            case .recurrings:
                moves = [:]
                upcoming = [:]
            }
        }
    }
}
