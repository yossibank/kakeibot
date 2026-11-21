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

    var commentRange: ClosedRange<LocalDate> {
        let range = period.range
        let end = range.contains(today) ? today : range.upperBound
        return range.lowerBound...end
    }

    var hasNewAnalysis: Bool {
        newAnalysisKey == period.commentKey
    }

    func refreshAnalysisMark() async {
        let key = period.commentKey

        guard
            Self.canWriteComment,
            list != nil,
            commentEntryCount >= ReviewComment.minimumEntries
        else {
            markAnalysis(key, isNew: false)
            return
        }

        let basis = commentFacts.basis
        let saved: ReviewComment?

        do {
            saved = try await database.reviewComment(for: key)
        } catch {
            return
        }

        guard !Task.isCancelled else {
            return
        }

        markAnalysis(key, isNew: saved?.needsRewrite(basis: basis) ?? true)
    }

    func refreshComment(
        retrying: Bool = false,
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
        let facts = commentFacts
        let breakdown = facts.breakdown
        let saved = try? await database.reviewComment(for: key)

        guard request == commentRequest else {
            return
        }

        savedComments[key] = saved

        if let saved,
           !saved.needsRewrite(basis: facts.basis) {
            markAnalysis(key, isNew: false)
            comment = .ready(saved)
            await loadNeighborComments()
            return
        }

        if !retrying,
           let failedAt = commentFailedAt[key],
           Calendar.current.isDate(failedAt, inSameDayAs: now) {
            comment = saved.map(CommentState.ready) ?? .failed
            return
        }

        let suggestion = breakdown?.suggestion ?? facts.insights.first?.suggestion(in: period) ?? ""

        comment = .loading

        let body = await Self.write(
            basis: facts.basis,
            scale: period.scale,
            categories: categoryNames + (breakdown?.names ?? []),
            isCurrent: isCurrent
        )

        guard request == commentRequest else {
            return
        }

        guard !Task.isCancelled else {
            comment = saved.map(CommentState.ready) ?? .loading
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
            basis: facts.basis,
            createdAt: now,
            breakdown: breakdown?.summary
        )

        try? await database.saveReviewComment(new)

        savedComments[key] = new
        writtenComments.insert(new)
        markAnalysis(key, isNew: false)
        comment = .ready(new)
    }

    func showSavedComment() {
        guard
            Self.canWriteComment,
            list != nil
        else {
            return
        }

        let count = commentEntryCount

        guard count >= ReviewComment.minimumEntries else {
            comment = .needsRecords(count)
            return
        }

        guard
            let saved = savedComments[period.commentKey],
            !saved.needsRewrite(basis: commentFacts.basis)
        else {
            comment = .loading
            return
        }

        comment = .ready(saved)
    }
}

extension ReviewModel {
    static var initialComment: CommentState {
        canWriteComment ? .loading : .hidden
    }

    var isWrittenNow: Bool {
        guard case let .ready(comment) = comment else {
            return false
        }

        return writtenComments.contains(comment)
    }

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

    var breakdownCategory: EntryCategory.ID? {
        let current = summary.expense.byCategory
        let previous = previousSummary.expense.byCategory
        let names = list?.categories.mapValues(\.name) ?? [:]
        let range = period.range

        let counts = entries.reduce(into: [EntryCategory.ID: Int]()) { counts, entry in
            guard
                entry.type == .expense,
                range.contains(entry.date),
                let id = entry.categoryId
            else {
                return
            }

            counts[id, default: 0] += 1
        }

        let ranked = current.keys.sorted { first, second in
            let firstName = names[first] ?? ""
            let secondName = names[second] ?? ""
            return firstName < secondName
        }

        let enough = ranked.filter { id in
            counts[id, default: 0] >= ReviewBreakdown.minimumCount
        }

        let rising = ranked
            .filter { previous[$0] != nil }
            .map { ($0, (current[$0] ?? 0) - (previous[$0] ?? 0)) }
            .filter { $0.1 > 0 }
            .max { $0.1 < $1.1 }?.0

        let largest = enough.max { (current[$0] ?? 0) < (current[$1] ?? 0) }

        return hasPreviousEntries ? rising ?? largest : largest
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
    struct CommentFacts {
        let insights: [ReviewInsight]
        let breakdown: ReviewBreakdown?
        let basis: String
    }

    static var canWriteComment: Bool {
        guard #available(iOS 26.0, *) else {
            return false
        }

        return ReviewCommentModel.isUsable
    }

    var categoryNames: [String] {
        list?.categories.values.map(\.name) ?? []
    }

    var commentFacts: CommentFacts {
        let insights = ReviewInsight.pick(from: insightInput)
        let breakdown = breakdownInput.flatMap(ReviewBreakdown.make(from:))
        let facts = ReviewComment.facts(insights, with: breakdown)

        return CommentFacts(
            insights: insights,
            breakdown: breakdown,
            basis: ReviewComment.basis(of: facts)
        )
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

    func loadNeighborComments() async {
        let keys = [period.adding(-1), period.adding(1)].map(\.commentKey)

        for key in keys where savedComments[key] == nil {
            guard let saved = try? await database.reviewComment(for: key) else {
                continue
            }

            savedComments[key] = saved
        }
    }

    func markAnalysis(
        _ key: String,
        isNew: Bool
    ) {
        if isNew {
            newAnalysisKey = key
        } else if newAnalysisKey == key {
            newAnalysisKey = nil
        }
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
        .sorted { $0.amount == $1.amount ? $0.name < $1.name : $0.amount > $1.amount }
    }
}
