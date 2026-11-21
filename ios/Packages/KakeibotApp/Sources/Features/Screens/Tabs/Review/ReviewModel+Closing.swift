import Core
import Foundation

extension ReviewModel {
    static let closingRows = 3
    static let streakLimit = 120

    var closingContent: ReviewClosingView.Content {
        let history = (1...Self.averagePeriods).map { period.adding(-$0).range }
        let compare = ReviewCompare(entries: entries, in: period.range, history: history)
        let previous = period.previous.range
        let hasPrevious = entries.contains { previous.contains($0.date) }
        let previousTotal = ReviewSummary(entries: entries, in: previous).expense.total
        let periods = (0..<Self.streakLimit).map { period.adding(-$0).range }

        return ReviewClosingView.Content(
            scale: scale,
            range: period.range,
            weekStart: weekStart,
            pace: pace,
            previousTotal: hasPrevious ? previousTotal : nil,
            rows: compare.rows.prefix(Self.closingRows).map { row in
                ReviewClosingView.CompareRow(name: categoryName(of: row.categoryId), row: row)
            },
            averagePeriods: compare.periods,
            special: compare.special.map { entry in
                ReviewClosingView.Special(
                    date: entry.date,
                    name: entry.memo ?? categoryName(of: entry.categoryId),
                    amount: entry.amount
                )
            },
            streak: ReviewStreak(entries: entries, in: period.range),
            continuing: ReviewStreak.continuing(entries: entries, periods: periods),
            budgetStreak: budgetStreak
        )
    }
}

private extension ReviewModel {
    var budgetStreak: Int {
        var count = 0
        var current = period

        while count < Self.streakLimit,
              let limit = budgetLimit(of: current),
              ReviewSummary(entries: entries, in: current.range).expense.total <= limit {
            count += 1
            current = current.previous
        }

        return count
    }

    func categoryName(of id: EntryCategory.ID?) -> String {
        id.flatMap { list?.categories[$0]?.name } ?? "未分類"
    }
}
