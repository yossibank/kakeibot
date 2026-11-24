import Core

public extension ReviewModel {
    struct MonthKey: Hashable {
        let range: ClosedRange<LocalDate>
    }
}

public extension ReviewModel.Output {
    var yearProgress: ReviewYearProgress? {
        guard
            input.scale == .year,
            isCurrentPeriod
        else {
            return nil
        }

        let range = period.range
        let comparison = period.comparisonRange(today: state.today)
        let hasPrevious = entries.contains { comparison.contains($0.date) }
        let spent = ReviewSummary(entries: entries, in: range.lowerBound...state.today).expense
            .total
        let previousSpent = ReviewSummary(entries: entries, in: comparison).expense.total

        let first = ReviewPeriod(
            scale: .month,
            containing: range.lowerBound,
            monthStartDay: input.monthStartDay,
            weekStart: input.weekStart
        )

        let months = (0..<ReviewModel.yearMonths)
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

    func monthShare(of month: ReviewYearProgress.Month) -> ReviewModel.Share {
        ReviewModel.Share(
            id: AnyHashable(ReviewModel.MonthKey(range: month.range)),
            name: month.name,
            icon: nil,
            amount: month.total,
            ratio: 0,
            usage: nil
        )
    }

    internal func monthRows(of key: ReviewModel.MonthKey) -> [EntryRowItem] {
        guard let list = input.list else {
            return []
        }

        return entries
            .filter { $0.type == .expense && key.range.contains($0.date) }
            .sorted { $0.date > $1.date }
            .map { entry in
                EntryRowItem.dated(entry, in: list)
            }
    }
}

private extension ReviewModel {
    static let yearMonths = 12
}

private extension ReviewModel.Output {
    func yearMonth(
        _ month: ReviewPeriod,
        index: Int
    ) -> ReviewYearProgress.Month {
        let total = ReviewSummary(entries: entries, in: month.range).expense.total
        let limit = budgetLimit(of: month)

        let state: ReviewYearProgress.State = if month.range.upperBound < state.today {
            .closed
        } else if month.range.contains(state.today) {
            .current
        } else {
            .upcoming
        }

        let isWithinBudget = state == .closed ? limit.map { total <= $0 } : nil

        return ReviewYearProgress.Month(
            id: index,
            range: month.range,
            name: month.displayName,
            total: total,
            state: state,
            isWithinBudget: isWithinBudget
        )
    }
}
