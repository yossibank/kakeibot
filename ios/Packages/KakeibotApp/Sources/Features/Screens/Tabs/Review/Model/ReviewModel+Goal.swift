import Core
import Foundation
import Store

extension ReviewModel {
    struct GoalTrigger: Hashable {
        let period: ReviewPeriod
        let isLoaded: Bool
    }

    var currentPeriod: ReviewPeriod {
        ReviewPeriod(
            scale: scale,
            containing: today,
            monthStartDay: monthStartDay,
            weekStart: weekStart
        )
    }

    var goalTrigger: GoalTrigger {
        GoalTrigger(period: currentPeriod, isLoaded: list != nil)
    }

    var hasNewReport: Bool {
        isCurrentPeriod && newReportKey != nil
    }

    func closingGoals(now: Date) -> ReviewClosingView.Goals {
        let next = period.adding(1)
        let answer = goals.first { $0.period == period.commentKey }
        let checked = answer.map { answered($0, now: now) }
        let nextGoal = goals.first { $0.period == next.commentKey }
        let nextItem = nextGoal.flatMap { goalItem($0, in: next) }
        let count = entryCount(in: period.range)
        let hasMore = closingContent.rows.contains { $0.row.tone == .more }

        let rests = next == currentPeriod
            && count >= ReviewComment.minimumEntries
            && !hasMore

        let nextCard: ReviewClosingView.Next = if let nextItem {
            .goal(nextItem, reason: goalReason(for: nextItem))
        } else if rests {
            .rest
        } else {
            .none
        }

        return ReviewClosingView.Goals(
            answer: checked.flatMap { goalItem($0, in: period) },
            next: nextCard,
            nextName: next.displayName,
            nextStart: next.range.lowerBound,
            checkDate: next.range.upperBound.adding(days: 1)
        )
    }

    func refreshGoals(now: Date) async {
        guard list != nil else {
            return
        }

        let current = currentPeriod
        let closed = current.previous

        do {
            try await checkGoals(of: closed, now: now)
            try await makeGoal(after: closed, for: current, now: now)

            let seen = try await database.setting(.reviewSeenReports)
            let hasEntries = entries.contains { closed.range.contains($0.date) }

            guard current == currentPeriod else {
                return
            }

            newReportKey = hasEntries && !seen.contains(closed.commentKey)
                ? closed.commentKey
                : nil
        } catch {
            return
        }

        await loadGoals()
    }

    func markReportSeen() async {
        let key = period.commentKey

        guard newReportKey == key else {
            return
        }

        newReportKey = nil

        do {
            let seen = try await database.setting(.reviewSeenReports)
            let prefix = "\(period.scale.rawValue):"
            let kept = seen.filter { !$0.hasPrefix(prefix) }

            try await database.setSetting(.reviewSeenReports, to: kept.union([key]))
        } catch {
            return
        }
    }
}

private extension ReviewModel {
    func answered(
        _ goal: ReviewGoal,
        now: Date
    ) -> ReviewGoal {
        guard goal.checkedAt == nil else {
            return goal
        }

        return goal.checked(entries: entries, in: period.range, now: now)
    }

    func checkGoals(
        of closed: ReviewPeriod,
        now: Date
    ) async throws {
        let goals = try await database.reviewGoals(for: closed.commentKey)

        for goal in goals where goal.checkedAt == nil {
            let checked = goal.checked(entries: entries, in: closed.range, now: now)
            try await database.saveReviewGoal(checked)
        }
    }

    func makeGoal(
        after closed: ReviewPeriod,
        for current: ReviewPeriod,
        now: Date
    ) async throws {
        let existing = try await database.reviewGoals(for: current.commentKey)
        let count = entryCount(in: closed.range)

        guard
            existing.isEmpty,
            count >= ReviewComment.minimumEntries
        else {
            return
        }

        let history = (1...Self.averagePeriods).map { closed.adding(-$0).range }

        let goal = ReviewGoal.make(
            entries: entries,
            closed: closed.range,
            history: history,
            period: current.commentKey,
            now: now
        )

        if let goal {
            try await database.saveReviewGoal(goal)
        }
    }
}
