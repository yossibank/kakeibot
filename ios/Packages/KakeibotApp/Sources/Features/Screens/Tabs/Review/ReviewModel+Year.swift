import Core

extension ReviewModel {
    var yearProgress: ReviewYearProgress? {
        guard
            scale == .year,
            isCurrentPeriod
        else {
            return nil
        }

        let range = period.range
        let comparison = period.comparisonRange(today: today)
        let hasPrevious = entries.contains { comparison.contains($0.date) }
        let spent = ReviewSummary(entries: entries, in: range.lowerBound...today).expense.total
        let previousSpent = ReviewSummary(entries: entries, in: comparison).expense.total

        let first = ReviewPeriod(
            scale: .month,
            containing: range.lowerBound,
            monthStartDay: monthStartDay,
            weekStart: weekStart
        )

        let months = (0..<Self.yearMonths)
            .map { first.adding($0) }
            .filter { $0.range.lowerBound <= range.upperBound }
            .enumerated()
            .map { index, month in
                yearMonth(month, index: index)
            }

        return ReviewYearProgress(
            months: months,
            spent: spent,
            previousSpent: hasPrevious ? previousSpent : nil
        )
    }
}

private extension ReviewModel {
    static let yearMonths = 12

    func yearMonth(
        _ month: ReviewPeriod,
        index: Int
    ) -> ReviewYearProgress.Month {
        let total = ReviewSummary(entries: entries, in: month.range).expense.total
        let limit = budgetLimit(of: month)

        let state: ReviewYearProgress.State = if month.range.upperBound < today {
            .closed
        } else if month.range.contains(today) {
            .current
        } else {
            .upcoming
        }

        let isWithinBudget = state == .closed ? limit.map { total <= $0 } : nil

        return ReviewYearProgress.Month(
            id: index,
            name: month.displayName,
            total: total,
            state: state,
            isWithinBudget: isWithinBudget
        )
    }
}
