import Core
import Foundation
import Store

public extension ReviewModel {
    enum CommentState: Hashable {
        case hidden
        case loading
        case ready(ReviewComment)
        case needsRecords(Int)
        case failed
    }

    enum Display: Hashable {
        case chart
        case analysis
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
        commentRequest += 1

        let request = commentRequest

        guard Self.canWriteComment else {
            comment = .hidden
            return
        }

        guard list != nil else {
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
        let input = breakdownInput
        let saved = try? await database.reviewComment(for: key)

        guard request == commentRequest else {
            return
        }

        let breakdown = input.flatMap(ReviewBreakdown.make(from:))
        let basis = ReviewComment.basis(of: ReviewComment.facts(insights, with: breakdown))

        if let saved,
           !rewriting,
           !saved.needsRewrite(basis: basis, isCurrent: isCurrent, today: now, calendar: .current) {
            comment = .ready(saved)
            return
        }

        if !rewriting,
           let failedAt = commentFailedAt[key],
           Calendar.current.isDate(failedAt, inSameDayAs: now) {
            comment = saved.map(CommentState.ready) ?? .failed
            return
        }

        comment = .loading

        let suggestion = breakdown?.suggestion ?? insights.first?.suggestion(in: period) ?? ""

        let body = await Self.write(
            basis: basis,
            scale: period.scale,
            categories: categoryNames + (breakdown?.names ?? []),
            isCurrent: isCurrent
        )

        guard request == commentRequest else {
            return
        }

        guard let body else {
            commentFailedAt[key] = now
            comment = saved.map(CommentState.ready) ?? .failed
            return
        }

        commentFailedAt[key] = nil

        let new = ReviewComment(
            period: key,
            body: body,
            suggestion: suggestion,
            basis: basis,
            createdAt: now,
            breakdown: breakdown?.summary
        )

        try? await database.saveReviewComment(new)

        comment = .ready(new)
    }
}

extension ReviewModel {
    var commentEntryCount: Int {
        let range = period.range
        return entries.count { range.contains($0.date) && $0.type != .transfer }
    }

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

    var breakdownInput: ReviewBreakdown.Input? {
        guard
            let list,
            let id = breakdownCategory,
            let category = list.categories[id]
        else {
            return nil
        }

        let range = period.range
        let comparison = period.comparisonRange(today: today)

        return ReviewBreakdown.Input(
            category: category.name,
            scale: scale,
            isCurrent: range.contains(today),
            hasPrevious: hasPreviousEntries,
            current: spends(in: range),
            previous: spends(in: comparison)
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

    var breakdownCategory: EntryCategory.ID? {
        let current = summary.expense.byCategory
        let previous = previousSummary.expense.byCategory
        let names = list?.categories.mapValues(\.name) ?? [:]

        let ranked = current.keys.sorted { first, second in
            let firstName = names[first] ?? ""
            let secondName = names[second] ?? ""
            return firstName < secondName
        }

        let rising = ranked
            .map { ($0, (current[$0] ?? 0) - (previous[$0] ?? 0)) }
            .filter { $0.1 > 0 }
            .max { $0.1 < $1.1 }?.0

        let largest = ranked.max { (current[$0] ?? 0) < (current[$1] ?? 0) }

        return hasPreviousEntries ? rising ?? largest : largest
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

    func spends(in range: ClosedRange<LocalDate>) -> [ReviewBreakdown.Spend] {
        entries.compactMap { entry in
            guard
                entry.type == .expense,
                range.contains(entry.date),
                let id = entry.categoryId,
                let category = list?.categories[id]
            else {
                return nil
            }

            return ReviewBreakdown.Spend(
                category: category.name,
                memo: entry.memo,
                amount: entry.amount
            )
        }
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
