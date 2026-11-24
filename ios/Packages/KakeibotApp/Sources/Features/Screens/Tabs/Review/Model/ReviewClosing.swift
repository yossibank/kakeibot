import Core

enum ReviewClosing {}

extension ReviewClosing {
    struct Content {
        let scale: ReviewPeriod.Scale
        let range: ClosedRange<LocalDate>
        let weekStart: Weekday
        let pace: ReviewPace?
        let spent: Int
        let previousTotal: Int?
        let rows: [CompareRow]
        let averagePeriods: Int
        let special: Special?
        let streak: ReviewStreak
        let continuing: Int
        let budgetStreak: Int
    }

    struct CompareRow: Identifiable {
        let name: String
        let row: ReviewCompare.Row

        var id: EntryCategory.ID {
            row.categoryId
        }
    }

    struct Special {
        let date: LocalDate
        let name: String
        let amount: Int
    }

    struct Notes {
        static let empty = Notes(summary: nil, whys: [:])

        let summary: String?
        let whys: [EntryCategory.ID: ReviewCompare.Why]
    }

    struct Goals {
        let answer: ReviewGoalItem?
        let next: Next
        let nextName: String
        let nextStart: LocalDate
        let checkDate: LocalDate
    }

    struct Reason: Hashable {
        let text: String
        let isWritten: Bool
    }

    enum Next {
        case none
        case rest
        case goal(ReviewGoalItem, reason: Reason?)
    }
}
