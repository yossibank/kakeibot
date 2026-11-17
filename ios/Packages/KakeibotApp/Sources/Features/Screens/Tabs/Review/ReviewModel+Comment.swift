import Core
import Foundation
import Store

public extension ReviewModel {
    enum CommentState: Hashable {
        case hidden
        case loading
        case ready(ReviewComment)
        case needsRecords(Int)
        case folded
        case failed
    }

    var commentRange: ClosedRange<LocalDate> {
        let range = period.range
        let end = range.contains(today) ? today : range.upperBound
        return range.lowerBound...end
    }

    func refreshComment(
        rewriting: Bool = false,
        now: Date = Date()
    ) async {
        guard Self.canWriteComment else {
            comment = .hidden
            return
        }

        guard list != nil else {
            return
        }

        let isFolded = await (try? database.setting(.reviewCommentFolded)) ?? false

        guard !isFolded else {
            comment = .folded
            return
        }

        let count = commentEntryCount

        guard count >= ReviewComment.minimumEntries else {
            comment = .needsRecords(count)
            return
        }

        let key = period.commentKey
        let isCurrent = period.range.contains(today)
        let insights = ReviewInsight.pick(from: insightInput)
        let basis = ReviewComment.basis(of: insights)
        let suggestion = insights.first?.suggestion(in: period) ?? ""
        let saved = try? await database.reviewComment(for: key)

        if let saved,
           !rewriting,
           !saved.needsRewrite(basis: basis, isCurrent: isCurrent, today: now, calendar: .current) {
            comment = .ready(saved)
            return
        }

        comment = .loading

        let body = await Self.write(
            basis: basis,
            scale: period.scale,
            categories: categoryNames,
            isCurrent: isCurrent
        )

        guard period.commentKey == key else {
            return
        }

        guard let body else {
            comment = saved.map(CommentState.ready) ?? .failed
            return
        }

        let new = ReviewComment(
            period: key,
            body: body,
            suggestion: suggestion,
            basis: basis,
            createdAt: now
        )

        try? await database.saveReviewComment(new)

        comment = .ready(new)
    }

    func foldComment(_ isFolded: Bool) async {
        try? await database.setSetting(.reviewCommentFolded, to: isFolded)
        await refreshComment()
    }
}

extension ReviewModel {
    var insightInput: ReviewInsight.Input {
        let range = period.range
        let isCurrent = range.contains(today)
        let totalDays = range.lowerBound.days(until: range.upperBound) + 1
        let elapsedDays = isCurrent ? range.lowerBound.days(until: today) + 1 : totalDays
        let current = summary
        let previous = previousSummary

        return ReviewInsight.Input(
            scale: period.scale,
            isCurrent: isCurrent,
            elapsedDays: elapsedDays,
            totalDays: totalDays,
            expense: current.expense.total,
            previousExpense: previous.expense.total,
            income: current.income.total,
            hasPrevious: hasPreviousEntries,
            categories: insightCategories(current: current, previous: previous),
            largestExpense: largestExpense
        )
    }
}

private extension ReviewModel {
    static var canWriteComment: Bool {
        guard #available(iOS 26.0, *) else {
            return false
        }

        return ReviewCommentModel.isUsable
    }

    var categoryNames: [String] {
        list?.categories.values.map(\.name) ?? []
    }

    var commentEntryCount: Int {
        let range = period.range
        return entries.count { range.contains($0.date) && $0.type != .transfer }
    }

    var largestExpense: ReviewInsight.Expense? {
        let range = period.range

        let largest = entries
            .filter { range.contains($0.date) && $0.type == .expense }
            .max { $0.amount < $1.amount }

        guard
            let largest,
            let categoryId = largest.categoryId,
            let category = list?.categories[categoryId]
        else {
            return nil
        }

        return ReviewInsight.Expense(categoryName: category.name, amount: largest.amount)
    }

    static func write(
        basis: String,
        scale: ReviewPeriod.Scale,
        categories: [String],
        isCurrent: Bool
    ) async -> String? {
        guard #available(iOS 26.0, *) else {
            return nil
        }

        return await ReviewCommentModel.write(
            basis: basis,
            scale: scale,
            categories: categories,
            isCurrent: isCurrent
        )
    }

    func insightCategories(
        current: ReviewSummary,
        previous: ReviewSummary
    ) -> [ReviewInsight.Category] {
        guard let list else {
            return []
        }

        let month = period.range.upperBound.yearMonth
        let ids = Set(current.expense.byCategory.keys).union(previous.expense.byCategory.keys)

        return ids.compactMap { id in
            guard let category = list.categories[id] else {
                return nil
            }

            let budget = scale == .month ? budgets.amount(for: id, in: month) : nil

            return ReviewInsight.Category(
                name: category.name,
                amount: current.expense.byCategory[id] ?? 0,
                previous: previous.expense.byCategory[id] ?? 0,
                budget: budget
            )
        }
        .sorted { $0.amount > $1.amount }
    }
}
