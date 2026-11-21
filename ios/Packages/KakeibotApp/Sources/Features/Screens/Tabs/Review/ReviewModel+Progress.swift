import Core
import Foundation
import Store

extension ReviewModel {
    static let averagePeriods = 3

    var pace: ReviewPace? {
        let spent = ReviewSummary(entries: entries, in: commentRange).expense.total

        if let limit = budgetLimit(of: period) {
            return ReviewPace(
                limit: limit,
                basis: .budget,
                spent: spent,
                range: period.range,
                today: today
            )
        }

        let totals = (1...Self.averagePeriods)
            .map { ReviewSummary(entries: entries, in: period.adding(-$0).range).expense.total }
            .filter { $0 > 0 }

        guard !totals.isEmpty else {
            return nil
        }

        return ReviewPace(
            limit: totals.reduce(0, +) / totals.count,
            basis: .average(periods: totals.count),
            spent: spent,
            range: period.range,
            today: today
        )
    }

    var goalItems: [ReviewProgressView.GoalItem] {
        let key = period.commentKey

        return goals.filter { $0.period == key }.compactMap { goal in
            let category = goal.categoryId.flatMap { list?.categories[$0]?.name }

            guard let name = goal.memo ?? category else {
                return nil
            }

            let progress = goal.progress(
                of: entries,
                in: period.range,
                today: today
            )

            return ReviewProgressView.GoalItem(
                goal: goal,
                name: name,
                progress: progress
            )
        }
    }

    func loadGoals() async {
        let key = period.commentKey

        guard let loaded = try? await database.reviewGoals(for: key) else {
            return
        }

        guard key == period.commentKey else {
            return
        }

        goals = loaded
    }
}

extension ReviewModel {
    func budgetLimit(of period: ReviewPeriod) -> Int? {
        guard period.scale == .month else {
            return nil
        }

        let month = period.range.upperBound.yearMonth
        return budgets.amount(for: nil, in: month).map { $0 + carryover(into: month) }
    }
}
