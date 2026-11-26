import Core

public enum ReviewClosing {}

public extension ReviewClosing {
    struct Content {
        public let scale: ReviewPeriod.Scale
        public let range: ClosedRange<LocalDate>
        public let weekStart: Weekday
        public let pace: ReviewPace?
        public let spent: Int
        public let previousTotal: Int?
        public let rows: [CompareRow]
        public let averagePeriods: Int
        public let special: Special?
        public let streak: ReviewStreak
        public let continuing: Int
        public let budgetStreak: Int
    }

    struct CompareRow: Identifiable {
        public let name: String
        public let row: ReviewCompare.Row
    }

    struct Special {
        public let date: LocalDate
        public let name: String
        public let amount: Int
    }

    struct Notes: Sendable {
        static let empty = Notes(summary: nil, whys: [:])

        public let summary: String?
        public let whys: [EntryCategory.ID: ReviewCompare.Why]
    }

    struct Goals {
        public let answer: ReviewGoalItem?
        public let next: Next
        public let nextName: String
        public let nextStart: LocalDate
        public let checkDate: LocalDate
    }

    struct Reason: Hashable {
        public let text: String
        public let isWritten: Bool
    }

    enum Next {
        case none
        case rest
        case goal(ReviewGoalItem, reason: Reason?)
    }
}

public extension ReviewClosing.CompareRow {
    var id: EntryCategory.ID {
        row.categoryId
    }
}
