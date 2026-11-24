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
}

extension ReviewModel.Output {
    var closingContent: ReviewClosingView.Content {
        let key = ReviewModel.ClosingKey(
            period: period,
            budgets: input.budgets,
            carryoverFrom: input.carryoverFrom
        )

        return closingContents.value(for: key) {
            makeClosingContent()
        }
    }
}

private extension ReviewModel.Output {
    var budgetStreak: Int {
        var count = 0
        var current = period

        while count < ReviewModel.streakLimit,
              let limit = budgetLimit(of: current),
              ReviewSummary(entries: entries, in: current.range).expense.total <= limit {
            count += 1
            current = current.previous
        }

        return count
    }

    func makeClosingContent() -> ReviewClosingView.Content {
        let history = (1...ReviewModel.averagePeriods).map { period.adding(-$0).range }
        let compare = ReviewCompare(entries: entries, in: period.range, history: history)
        let spent = ReviewSummary(entries: entries, in: period.range).expense.total
        let previous = period.previous.range
        let hasPrevious = entries.contains { previous.contains($0.date) }
        let previousTotal = ReviewSummary(entries: entries, in: previous).expense.total
        let periods = (0..<ReviewModel.streakLimit).map { period.adding(-$0).range }

        let streak = ReviewStreak(
            entries: entries,
            noSpendDays: input.noSpendDays,
            in: period.range
        )

        let continuing = ReviewStreak.continuing(
            entries: entries,
            noSpendDays: input.noSpendDays,
            periods: periods
        )

        return ReviewClosingView.Content(
            scale: input.scale,
            range: period.range,
            weekStart: input.weekStart,
            pace: pace,
            spent: spent,
            previousTotal: hasPrevious ? previousTotal : nil,
            rows: compare.rows.prefix(ReviewModel.closingRows).map { row in
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
        id.flatMap { input.list?.categories[$0]?.name } ?? "未分類"
    }
}
