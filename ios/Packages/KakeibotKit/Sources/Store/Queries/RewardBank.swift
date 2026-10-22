import Core

public struct RewardBank: Equatable, Sendable {
    public let rules: [RewardRule]
    public let icons: [Icon.ID: Icon]
    public let logs: [RewardLog]
    public let goals: [RewardGoal]

    public init(
        rules: [RewardRule],
        icons: [Icon.ID: Icon],
        logs: [RewardLog],
        goals: [RewardGoal]
    ) {
        self.rules = rules
        self.icons = icons
        self.logs = logs
        self.goals = goals
    }
}

public extension RewardBank {
    var balance: Int {
        RewardBalance.amount(logs: logs, goals: goals)
    }

    var activeRules: [RewardRule] {
        rules.filter(\.isActive)
    }

    func rule(for log: RewardLog) -> RewardRule? {
        rules.first { $0.id == log.ruleId }
    }

    func icon(for rule: RewardRule) -> Icon? {
        icons[rule.iconId]
    }

    func logs(on date: LocalDate) -> [RewardLog] {
        logs.filter { $0.date == date }
    }

    func total(on date: LocalDate) -> Int {
        logs(on: date).reduce(0) { $0 + $1.amount }
    }
}
