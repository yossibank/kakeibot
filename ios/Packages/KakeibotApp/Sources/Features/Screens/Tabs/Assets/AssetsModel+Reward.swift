import Core
import Foundation
import Store

public extension AssetsModel {
    struct RewardMonth: Equatable {
        public let month: YearMonth
        public let logs: [RewardLog]
    }

    var rewardBalance: Int {
        rewardBank?.balance ?? 0
    }

    var recentRewards: [RewardLog] {
        let logs = rewardBank?.logs ?? []
        return Array(logs.prefix(Self.recentRewardCount))
    }

    var rewardGoal: RewardGoal? {
        rewardBank?.waitingGoals.first
    }

    var isRewardGoalReached: Bool {
        rewardGoal.map { remaining(to: $0) == 0 } ?? false
    }

    var rewardRules: [RewardRule] {
        rewardBank?.activeRules ?? []
    }

    var waitingGoals: [RewardGoal] {
        rewardBank?.waitingGoals ?? []
    }

    var boughtGoals: [RewardGoal] {
        rewardBank?.boughtGoals ?? []
    }

    var rewardHistory: [RewardMonth] {
        var months: [RewardMonth] = []

        for log in rewardBank?.logs ?? [] {
            let month = log.date.yearMonth

            if let last = months.last,
               last.month == month {
                let logs = last.logs + [log]
                months[months.count - 1] = RewardMonth(month: month, logs: logs)
            } else {
                let first = RewardMonth(month: month, logs: [log])
                months.append(first)
            }
        }

        return months
    }

    func remaining(to goal: RewardGoal) -> Int {
        rewardBank?.remaining(to: goal) ?? goal.targetAmount
    }

    func progress(to goal: RewardGoal) -> Double {
        rewardBank?.progress(to: goal) ?? 0
    }

    func percent(to goal: RewardGoal) -> Int {
        rewardBank?.percent(to: goal) ?? 0
    }

    func goalEditModel(editing goal: RewardGoal?) -> AssetsGoalEditModel {
        AssetsGoalEditModel(database: database, editing: goal)
    }

    @discardableResult
    func setPurchased(
        _ id: RewardGoal.ID,
        isPurchased: Bool
    ) async -> Bool {
        do {
            try await database.setRewardGoalPurchased(
                id,
                isPurchased: isPurchased,
                at: Date()
            )

            return true
        } catch {
            errorNotice.show(Self.goalFailedMessage)
            return false
        }
    }

    func rewardRule(for log: RewardLog) -> RewardRule? {
        rewardBank?.rule(for: log)
    }

    func rewardIcon(for rule: RewardRule) -> Icon? {
        rewardBank?.icon(for: rule)
    }
}

private extension AssetsModel {
    static let recentRewardCount = 3
    static let goalFailedMessage = "目標を保存できませんでした"
}

extension AssetsModel.RewardMonth: Identifiable {
    public var id: YearMonth {
        month
    }
}
