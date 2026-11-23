import Core
import GRDB

public extension AppDatabase {
    func rewardRuleListUpdates() -> some AsyncSequence<RewardRuleList, any Error> {
        ValueObservation.tracking(Self.rewardRuleList).values(in: writer)
    }

    func rewardRuleList() async throws -> RewardRuleList {
        try await writer.read(Self.rewardRuleList)
    }
}

private extension AppDatabase {
    static func rewardRuleList(in db: Database) throws -> RewardRuleList {
        let rules = try RewardRule.order(RewardRule.sortOrder, Column("created_at")).fetchAll(db)
        let iconIds = rules.map(\.iconId)
        let icons = try Icon.byID(iconIds, in: db)
        let totals = try rewardTotals(in: db)
        return RewardRuleList(rules: rules, icons: icons, totals: totals)
    }

    static func rewardTotals(in db: Database) throws -> [RewardRule.ID: RewardRuleList.Total] {
        let rows = try Row.fetchAll(
            db,
            sql: """
            SELECT rule_id, COUNT(*) AS count, SUM(amount) AS amount
            FROM reward_log
            GROUP BY rule_id
            """
        )

        let pairs = rows.map { row in
            let total = RewardRuleList.Total(count: row["count"], amount: row["amount"])
            return (row["rule_id"] as RewardRule.ID, total)
        }

        return Dictionary(uniqueKeysWithValues: pairs)
    }
}
