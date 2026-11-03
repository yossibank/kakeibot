public enum RewardBalance {
    public static func amount(
        logs: [RewardLog],
        goals: [RewardGoal]
    ) -> Int {
        let saved = logs.reduce(0) { $0 + $1.amount }
        let bought = goals.filter { $0.purchasedAt != nil }
        let spent = bought.reduce(0) { $0 + $1.targetAmount }
        return saved - spent
    }
}
