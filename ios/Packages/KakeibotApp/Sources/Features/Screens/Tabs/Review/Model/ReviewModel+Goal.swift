import Core
import Foundation
import Store

extension ReviewModel {
    struct GoalTrigger: Hashable {
        let period: ReviewPeriod
        let isLoaded: Bool
    }

    func refreshGoals() async {
        guard input.list != nil else {
            return
        }

        let now = dependencies.clock.now
        state.checkTime = now

        let current = output.currentPeriod
        let closed = current.previous

        do {
            try await checkGoals(of: closed, now: now)
            try await makeGoal(after: closed, for: current, now: now)

            let seen = try await dependencies.database.setting(.reviewSeenReports)
            let hasEntries = output.entries.contains { closed.range.contains($0.date) }

            guard current == output.currentPeriod else {
                return
            }

            state.newReportKey = hasEntries && !seen.contains(closed.commentKey)
                ? closed.commentKey
                : nil
        } catch {
            return
        }

        await loadGoals()
    }

    func markReportSeen() async {
        let key = output.period.commentKey

        guard state.newReportKey == key else {
            return
        }

        state.newReportKey = nil

        do {
            let seen = try await dependencies.database.setting(.reviewSeenReports)
            let prefix = "\(output.period.scale.rawValue):"
            let kept = seen.filter { !$0.hasPrefix(prefix) }

            try await dependencies.database.setSetting(.reviewSeenReports, to: kept.union([key]))
        } catch {
            return
        }
    }
}

extension ReviewModel.Output {
    var currentPeriod: ReviewPeriod {
        ReviewPeriod(
            scale: input.scale,
            containing: state.today,
            monthStartDay: input.monthStartDay,
            weekStart: input.weekStart
        )
    }

    var goalTrigger: ReviewModel.GoalTrigger {
        ReviewModel.GoalTrigger(period: currentPeriod, isLoaded: input.list != nil)
    }

    var hasNewReport: Bool {
        isCurrentPeriod && state.newReportKey != nil
    }

    var closingGoals: ReviewClosing.Goals {
        let next = period.adding(1)
        let answer = input.goals.first { $0.period == period.commentKey }
        let checked = answer.map { answered($0, now: state.checkTime) }
        let nextGoal = input.goals.first { $0.period == next.commentKey }
        let nextItem = nextGoal.flatMap { goalItem($0, in: next) }
        let count = entryCount(in: period.range)
        let hasMore = closingContent.rows.contains { $0.row.tone == .more }

        let rests = next == currentPeriod
            && count >= ReviewComment.minimumEntries
            && !hasMore

        let nextCard: ReviewClosing.Next = if let nextItem {
            .goal(nextItem, reason: goalReason(for: nextItem))
        } else if rests {
            .rest
        } else {
            .none
        }

        return ReviewClosing.Goals(
            answer: checked.flatMap { goalItem($0, in: period) },
            next: nextCard,
            nextName: next.displayName,
            nextStart: next.range.lowerBound,
            checkDate: next.range.upperBound.adding(days: 1)
        )
    }
}

private extension ReviewModel {
    func checkGoals(
        of closed: ReviewPeriod,
        now: Date
    ) async throws {
        let goals = try await dependencies.database.reviewGoals(for: closed.commentKey)

        for goal in goals where goal.checkedAt == nil {
            let checked = goal.checked(entries: output.entries, in: closed.range, now: now)
            try await dependencies.database.saveReviewGoal(checked)
        }
    }

    func makeGoal(
        after closed: ReviewPeriod,
        for current: ReviewPeriod,
        now: Date
    ) async throws {
        let existing = try await dependencies.database.reviewGoals(for: current.commentKey)
        let count = output.entryCount(in: closed.range)

        guard
            existing.isEmpty,
            count >= ReviewComment.minimumEntries
        else {
            return
        }

        let history = (1...Self.averagePeriods).map { closed.adding(-$0).range }

        let goal = ReviewGoal.make(
            entries: output.entries,
            closed: closed.range,
            history: history,
            period: current.commentKey,
            now: now
        )

        if let goal {
            try await dependencies.database.saveReviewGoal(goal)
        }
    }
}

private extension ReviewModel.Output {
    func answered(
        _ goal: ReviewGoal,
        now: Date
    ) -> ReviewGoal {
        guard goal.checkedAt == nil else {
            return goal
        }

        return goal.checked(entries: entries, in: period.range, now: now)
    }
}
