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

    var goalItems: [ReviewGoalItem] {
        let key = period.commentKey

        return goals.filter { $0.period == key }.compactMap { goal in
            goalItem(goal, in: period)
        }
    }

    func goalItem(
        _ goal: ReviewGoal,
        in period: ReviewPeriod
    ) -> ReviewGoalItem? {
        guard let category = goal.categoryId.flatMap({ list?.categories[$0]?.name }) else {
            return nil
        }

        let progress = goal.progress(
            of: entries,
            in: period.range,
            today: today
        )

        return ReviewGoalItem(
            goal: goal,
            name: goal.memo ?? category,
            categoryName: category,
            progress: progress
        )
    }

    func loadGoals() async {
        let key = period.commentKey
        let nextKey = period.adding(1).commentKey

        do {
            let loaded = try await database.reviewGoals(for: key)
            let next = try await database.reviewGoals(for: nextKey)

            guard key == period.commentKey else {
                return
            }

            goals = loaded + next
        } catch {
            return
        }
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
