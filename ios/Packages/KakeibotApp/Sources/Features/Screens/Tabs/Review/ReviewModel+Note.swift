import Core
import Foundation
import Store

extension ReviewModel {
    struct NoteTrigger: Hashable {
        let period: String
        let basis: String?
    }

    var noteTrigger: NoteTrigger {
        let basis = list == nil ? nil : closingFacts.basis
        return NoteTrigger(period: period.commentKey, basis: basis)
    }

    var closingNotes: ReviewClosingView.Notes {
        let range = period.range
        let history = (1...Self.averagePeriods).map { period.adding(-$0).range }
        let rising = closingContent.rows.filter { $0.row.tone == .more }

        let pairs = rising.compactMap { item in
            let why = ReviewCompare.why(
                entries: entries,
                categoryId: item.id,
                in: range,
                history: history
            )

            return why.map { (item.id, $0) }
        }

        return ReviewClosingView.Notes(
            summary: notes[Self.summaryKey(period.commentKey)],
            whys: Dictionary(uniqueKeysWithValues: pairs)
        )
    }

    func refreshNotes(now: Date = Date()) async {
        let key = Self.summaryKey(period.commentKey)
        let facts = closingFacts
        let basis = facts.basis
        let request = "\(key)\n\(basis)"

        guard
            list != nil,
            !isCurrentPeriod,
            !noteRequests.contains(request),
            entryCount(in: period.range) >= ReviewComment.minimumEntries
        else {
            return
        }

        noteRequests.insert(request)

        let saved = try? await database.reviewComment(for: key)

        if let saved,
           !saved.needsRewrite(basis: basis) {
            notes[key] = saved.body
            return
        }

        let names = closingContent.rows.map(\.name)

        guard let body = await Self.writeSummary(facts: facts, scale: scale, categories: names)
        else {
            noteRequests.remove(request)
            return
        }

        let comment = ReviewComment(
            period: key,
            body: body,
            basis: basis,
            createdAt: now
        )

        try? await database.saveReviewComment(comment)

        notes[key] = body
    }
}

private extension ReviewModel {
    static let dailyRatio = 0.8

    var closingFacts: ReviewClosingFacts {
        let content = closingContent
        let range = content.range
        let totalDays = range.lowerBound.days(until: range.upperBound) + 1
        let recorded = Double(content.streak.days.count) / Double(totalDays)

        return ReviewClosingFacts(
            verdict: Self.verdict(of: content.pace),
            more: content.rows.filter { $0.row.tone == .more }.map(\.name),
            less: content.rows.filter { $0.row.tone == .less }.map(\.name),
            isGoalAchieved: closingGoals().answer?.goal.isAchieved,
            recordsDaily: recorded >= Self.dailyRatio
        )
    }

    static func summaryKey(_ key: String) -> String {
        "summary:\(key)"
    }

    static func verdict(of pace: ReviewPace?) -> ReviewClosingFacts.Verdict? {
        guard let pace else {
            return nil
        }

        switch pace.basis {
        case .budget:
            return pace.verdict == .over ? .overBudget : .withinBudget

        case .average:
            return switch ReviewCompare.tone(amount: pace.spent, average: pace.limit) {
            case .more: .more
            case .less: .less
            case .usual: .usual
            }
        }
    }

    static func writeSummary(
        facts: ReviewClosingFacts,
        scale: ReviewPeriod.Scale,
        categories: [String]
    ) async -> String? {
        guard #available(iOS 26.0, *) else {
            return nil
        }

        return await ReviewNoteModel.summary(facts: facts, scale: scale, categories: categories)
    }
}
