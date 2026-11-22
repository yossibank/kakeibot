import Core
import Foundation

extension ReviewModel {
    struct ClosingKey: Hashable {
        let period: ReviewPeriod
        let budgets: [Budget]
        let carryoverFrom: YearMonth?
    }

    static let closingRows = 3
    static let streakLimit = 120

    var closingContent: ReviewClosingView.Content {
        let key = ClosingKey(
            period: period,
            budgets: budgets,
            carryoverFrom: carryoverFrom
        )

        if let cached = closingCache[key] {
            return cached
        }

        let content = makeClosingContent()

        closingCache[key] = content

        return content
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

    func makeClosingContent() -> ReviewClosingView.Content {
        let history = (1...Self.averagePeriods).map { period.adding(-$0).range }
        let compare = ReviewCompare(entries: entries, in: period.range, history: history)
        let spent = ReviewSummary(entries: entries, in: period.range).expense.total
        let previous = period.previous.range
        let hasPrevious = entries.contains { previous.contains($0.date) }
        let previousTotal = ReviewSummary(entries: entries, in: previous).expense.total
        let periods = (0..<Self.streakLimit).map { period.adding(-$0).range }

        let streak = ReviewStreak(
            entries: entries,
            noSpendDays: noSpendDays,
            in: period.range
        )

        let continuing = ReviewStreak.continuing(
            entries: entries,
            noSpendDays: noSpendDays,
            periods: periods
        )

        return ReviewClosingView.Content(
            scale: scale,
            range: period.range,
            weekStart: weekStart,
            pace: pace,
            spent: spent,
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
            streak: streak,
            continuing: continuing,
            budgetStreak: budgetStreak
        )
    }

    func categoryName(of id: EntryCategory.ID?) -> String {
        id.flatMap { list?.categories[$0]?.name } ?? "未分類"
    }
}
