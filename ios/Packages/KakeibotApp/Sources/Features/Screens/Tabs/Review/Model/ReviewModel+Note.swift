import Core
import Foundation
import Store

extension ReviewModel {
    struct NoteTrigger: Hashable {
        let period: String
        let basis: String?
    }

    func refreshNotes() async {
        let now = dependencies.clock.now
        let key = Self.summaryKey(output.period.commentKey)
        let facts = output.closingFacts
        let basis = facts.basis
        let request = "\(key)\n\(basis)"

        guard
            input.list != nil,
            !output.isCurrentPeriod,
            !input.noteRequests.contains(request),
            output.entryCount(in: output.period.range) >= ReviewComment.minimumEntries
        else {
            return
        }

        input.noteRequests.insert(request)

        let saved = try? await dependencies.database.reviewComment(for: key)

        if let saved,
           !saved.needsRewrite(basis: basis) {
            input.notes[key] = saved.body
            return
        }

        let names = output.closingContent.rows.map(\.name)

        guard let body = await Self.writeSummary(
            facts: facts,
            scale: input.scale,
            categories: names
        )
        else {
            input.noteRequests.remove(request)
            return
        }

        let comment = ReviewComment(
            period: key,
            body: body,
            basis: basis,
            createdAt: now
        )

        try? await dependencies.database.saveReviewComment(comment)

        input.notes[key] = body
    }
}

extension ReviewModel.Output {
    var closingNotes: ReviewClosingView.Notes {
        let range = period.range
        let history = (1...ReviewModel.averagePeriods).map { period.adding(-$0).range }
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
            summary: input.notes[ReviewModel.summaryKey(period.commentKey)],
            whys: Dictionary(uniqueKeysWithValues: pairs)
        )
    }

    var noteTrigger: ReviewModel.NoteTrigger {
        let basis = input.list == nil ? nil : closingFacts.basis
        return ReviewModel.NoteTrigger(period: period.commentKey, basis: basis)
    }
}

private extension ReviewModel {
    static let dailyRatio = 0.8

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

        return await ReviewNoteWriter.summary(facts: facts, scale: scale, categories: categories)
    }
}

private extension ReviewModel.Output {
    var closingFacts: ReviewClosingFacts {
        let content = closingContent
        let range = content.range
        let totalDays = range.lowerBound.days(until: range.upperBound) + 1
        let recorded = Double(content.streak.days.count) / Double(totalDays)

        return ReviewClosingFacts(
            verdict: ReviewModel.verdict(of: content.pace),
            more: content.rows.filter { $0.row.tone == .more }.map(\.name),
            less: content.rows.filter { $0.row.tone == .less }.map(\.name),
            isGoalAchieved: closingGoals.answer?.goal.isAchieved,
            recordsDaily: recorded >= ReviewModel.dailyRatio
        )
    }
}
