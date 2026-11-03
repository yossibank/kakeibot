import Core

public struct RewardRuleList: Equatable, Sendable {
    public let rules: [RewardRule]
    public let icons: [Icon.ID: Icon]
    public let totals: [RewardRule.ID: Total]

    public init(
        rules: [RewardRule],
        icons: [Icon.ID: Icon],
        totals: [RewardRule.ID: Total] = [:]
    ) {
        self.rules = rules
        self.icons = icons
        self.totals = totals
    }
}

public extension RewardRuleList {
    struct Total: Equatable, Sendable {
        public let count: Int
        public let amount: Int

        public init(
            count: Int,
            amount: Int
        ) {
            self.count = count
            self.amount = amount
        }
    }

    func total(of rule: RewardRule) -> Total? {
        totals[rule.id]
    }
}
