import Core
import Store

public extension AssetsModel.Output {
    var rewardBalance: Int {
        input.rewardBank?.balance ?? 0
    }

    var recentRewards: [RewardLog] {
        let logs = input.rewardBank?.logs ?? []
        return Array(logs.prefix(Self.recentRewardCount))
    }

    var rewardGoal: RewardGoal? {
        input.rewardBank?.waitingGoals.first
    }

    var isRewardGoalReached: Bool {
        rewardGoal.map { remaining(to: $0) == 0 } ?? false
    }

    var rewardRules: [RewardRule] {
        input.rewardBank?.activeRules ?? []
    }

    var waitingGoals: [RewardGoal] {
        input.rewardBank?.waitingGoals ?? []
    }

    var boughtGoals: [RewardGoal] {
        input.rewardBank?.boughtGoals ?? []
    }

    var rewardHistory: [AssetsModel.RewardMonth] {
        var months: [AssetsModel.RewardMonth] = []

        for log in input.rewardBank?.logs ?? [] {
            let month = log.date.yearMonth

            if let last = months.last,
               last.month == month {
                let logs = last.logs + [log]
                months[months.count - 1] = AssetsModel.RewardMonth(month: month, logs: logs)
            } else {
                let first = AssetsModel.RewardMonth(month: month, logs: [log])
                months.append(first)
            }
        }

        return months
    }

    func remaining(to goal: RewardGoal) -> Int {
        input.rewardBank?.remaining(to: goal) ?? goal.targetAmount
    }

    func progress(to goal: RewardGoal) -> Double {
        input.rewardBank?.progress(to: goal) ?? 0
    }

    func percent(to goal: RewardGoal) -> Int {
        input.rewardBank?.percent(to: goal) ?? 0
    }

    func rewardRule(for log: RewardLog) -> RewardRule? {
        input.rewardBank?.rule(for: log)
    }

    func rewardIcon(for rule: RewardRule) -> Icon? {
        input.rewardBank?.icon(for: rule)
    }
}

private extension AssetsModel.Output {
    static let recentRewardCount = 3
}
