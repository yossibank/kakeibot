import Core
import Foundation
import Store

extension ReviewModel {
    static let averagePeriods = 3

    public func loadGoals() async {
        let key = output.period.commentKey
        let nextKey = output.period.adding(1).commentKey

        do {
            let loaded = try await dependencies.database.reviewGoals(for: key)
            let next = try await dependencies.database.reviewGoals(for: nextKey)

            guard key == output.period.commentKey else {
                return
            }

            input.goals = loaded + next
        } catch {
            return
        }
    }
}

public extension ReviewModel.Output {
    var elapsedRange: ClosedRange<LocalDate> {
        let range = period.range
        let end = range.contains(state.today) ? state.today : range.upperBound
        return range.lowerBound...end
    }

    var pace: ReviewPace? {
        let spent = ReviewSummary(entries: entries, in: elapsedRange).expense.total

        if let limit = budgetLimit(of: period) {
            return ReviewPace(
                limit: limit,
                basis: .budget,
                spent: spent,
                range: period.range,
                today: state.today
            )
        }

        let totals = (1...ReviewModel.averagePeriods)
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
            today: state.today
        )
    }

    var goalItems: [ReviewGoalItem] {
        let key = period.commentKey

        return input.goals.filter { $0.period == key }.compactMap { goal in
            goalItem(goal, in: period)
        }
    }

    internal func goalItem(
        _ goal: ReviewGoal,
        in period: ReviewPeriod
    ) -> ReviewGoalItem? {
        guard let category = goal.categoryId.flatMap({ input.list?.categories[$0]?.name }) else {
            return nil
        }

        let progress = goal.progress(
            of: entries,
            in: period.range,
            today: state.today
        )

        return ReviewGoalItem(
            goal: goal,
            name: goal.memo ?? category,
            categoryName: category,
            progress: progress
        )
    }
}

extension ReviewModel.Output {
    func budgetLimit(of period: ReviewPeriod) -> Int? {
        guard period.scale == .month else {
            return nil
        }

        let month = period.range.upperBound.yearMonth
        return input.budgets.amount(for: nil, in: month).map { $0 + carryover(into: month) }
    }
}
