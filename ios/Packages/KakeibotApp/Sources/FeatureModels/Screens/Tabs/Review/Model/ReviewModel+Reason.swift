import Core
import Foundation
import Store

public extension ReviewModel {
    struct ReasonTrigger: Hashable {
        let period: String
        let goalId: ReviewGoal.ID?
    }

    func refreshReason() async {
        let now = dependencies.clock.now
        let key = output.period.commentKey
        let next = output.period.adding(1)

        guard
            !output.isCurrentPeriod,
            !input.reasonRequests.contains(key),
            let goal = input.goals.first(where: { $0.period == next.commentKey }),
            let item = output.goalItem(goal, in: next)
        else {
            return
        }

        input.reasonRequests.insert(key)

        let basis = output.reasonBasis(for: item)
        let saved = try? await dependencies.database.reviewComment(for: key)

        if let saved,
           !saved.needsRewrite(basis: basis) {
            input.reasons[key] = saved.body
            return
        }

        let body = await Self.writeReason(
            basis: basis,
            scale: output.period.scale,
            categories: [item.categoryName]
        )

        guard let body else {
            input.reasonRequests.remove(key)
            return
        }

        let comment = ReviewComment(
            period: key,
            body: body,
            basis: basis,
            createdAt: now
        )

        try? await dependencies.database.saveReviewComment(comment)

        input.reasons[key] = body
    }
}

extension ReviewModel.Output {
    public var reasonTrigger: ReviewModel.ReasonTrigger {
        let next = period.adding(1).commentKey
        let goal = input.goals.first { $0.period == next }
        return ReviewModel.ReasonTrigger(period: period.commentKey, goalId: goal?.id)
    }

    func goalReason(for item: ReviewGoalItem) -> ReviewClosing.Reason? {
        if let written = input.reasons[period.commentKey] {
            return ReviewClosing.Reason(text: written, isWritten: true)
        }

        return factReason(for: item).map { text in
            ReviewClosing.Reason(text: text, isWritten: false)
        }
    }
}

private extension ReviewModel {
    static func writeReason(
        basis: String,
        scale: ReviewPeriod.Scale,
        categories: [String]
    ) async -> String? {
        guard #available(iOS 26.0, *) else {
            return nil
        }

        return await ReviewCommentWriter.write(
            basis: basis,
            scale: scale,
            categories: categories
        )
    }
}

private extension ReviewModel.Output {
    var reasonRow: ReviewClosing.CompareRow? {
        let next = period.adding(1).commentKey
        let goal = input.goals.first { $0.period == next }
        return closingContent.rows.first { $0.row.categoryId == goal?.categoryId }
    }

    func factReason(for item: ReviewGoalItem) -> String? {
        guard let row = reasonRow else {
            return nil
        }

        let name = period.displayName
        let difference = ReviewYen.text(row.row.difference)
        let first = "\(name)は\(item.categoryName)がいつもより \(difference) 多めでした。"

        guard let memo = item.goal.memo else {
            return first
        }

        return first + "増えたのは\(memo)です。"
    }

    func reasonBasis(for item: ReviewGoalItem) -> String {
        let goal = item.goal
        let unit = input.scale.unitName

        let spent = reasonRow.map { row in
            let amount = ReviewYen.text(row.row.amount)
            let average = ReviewYen.text(row.row.average)

            return "\(item.categoryName)は、この\(unit)に \(amount) 使いました。いつもは \(average) です。"
        }

        let value = switch goal.kind {
        case .count: "\(item.name)の記録は、この\(unit)に \(goal.baseline) 回でした。"
        case .average: "\(item.name)の 1 回の平均は、この\(unit)は \(ReviewYen.text(goal.baseline)) でした。"
        }

        return [spent, value].compactMap(\.self).joined(separator: "\n")
    }
}
