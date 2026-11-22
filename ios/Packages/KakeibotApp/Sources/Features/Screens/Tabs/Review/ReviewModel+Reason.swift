import Core
import Foundation
import Store

extension ReviewModel {
    struct ReasonTrigger: Hashable {
        let period: String
        let goalId: ReviewGoal.ID?
    }

    var reasonTrigger: ReasonTrigger {
        let next = period.adding(1).commentKey
        let goal = goals.first { $0.period == next }
        return ReasonTrigger(period: period.commentKey, goalId: goal?.id)
    }

    func goalReason(for item: ReviewGoalItem) -> String? {
        reasons[period.commentKey] ?? factReason(for: item)
    }

    func refreshReason(now: Date = Date()) async {
        let key = period.commentKey
        let next = period.adding(1)

        guard
            !isCurrentPeriod,
            !reasonRequests.contains(key),
            let goal = goals.first(where: { $0.period == next.commentKey }),
            let item = goalItem(goal, in: next)
        else {
            return
        }

        reasonRequests.insert(key)

        let basis = reasonBasis(for: item)
        let saved = try? await database.reviewComment(for: key)

        if let saved,
           !saved.needsRewrite(basis: basis) {
            reasons[key] = saved.body
            return
        }

        let body = await Self.writeReason(
            basis: basis,
            scale: period.scale,
            categories: [item.categoryName]
        )

        guard let body else {
            reasonRequests.remove(key)
            return
        }

        let comment = ReviewComment(
            period: key,
            body: body,
            basis: basis,
            createdAt: now
        )

        try? await database.saveReviewComment(comment)

        reasons[key] = body
    }
}

private extension ReviewModel {
    var reasonRow: ReviewClosingView.CompareRow? {
        let next = period.adding(1).commentKey
        let goal = goals.first { $0.period == next }
        return closingContent.rows.first { $0.row.categoryId == goal?.categoryId }
    }

    static func writeReason(
        basis: String,
        scale: ReviewPeriod.Scale,
        categories: [String]
    ) async -> String? {
        guard #available(iOS 26.0, *) else {
            return nil
        }

        return await ReviewCommentModel.write(
            basis: basis,
            scale: scale,
            categories: categories
        )
    }

    func factReason(for item: ReviewGoalItem) -> String? {
        guard let row = reasonRow else {
            return nil
        }

        let name = period.displayName
        let difference = ReviewInsight.yen(row.row.difference)
        let first = "\(name)は\(item.categoryName)がいつもより \(difference) 多めでした。"

        guard let memo = item.goal.memo else {
            return first
        }

        return first + "増えたのは\(memo)です。"
    }

    func reasonBasis(for item: ReviewGoalItem) -> String {
        let goal = item.goal
        let unit = scale.unitName

        let spent = reasonRow.map { row in
            let amount = ReviewInsight.yen(row.row.amount)
            let average = ReviewInsight.yen(row.row.average)

            return "\(item.categoryName)は、この\(unit)に \(amount) 使いました。いつもは \(average) です。"
        }

        let value = switch goal.kind {
        case .count: "\(item.name)の記録は、この\(unit)に \(goal.baseline) 回でした。"
        case .average: "\(item.name)の 1 回の平均は、この\(unit)は \(ReviewInsight.yen(goal.baseline)) でした。"
        }

        return [spent, value].compactMap(\.self).joined(separator: "\n")
    }
}
