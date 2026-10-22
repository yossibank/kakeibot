import Core
import GRDB

public extension AppDatabase {
    func rewardRuleListUpdates() -> some AsyncSequence<
        RewardRuleList,
        any Error
    > {
        ValueObservation
            .tracking(Self.rewardRuleList)
            .values(in: writer)
    }

    func rewardRuleList() async throws -> RewardRuleList {
        try await writer.read(Self.rewardRuleList)
    }
}

private extension AppDatabase {
    static func rewardRuleList(in db: Database) throws -> RewardRuleList {
        let rules = try RewardRule
            .order(RewardRule.sortOrder, Column("created_at"))
            .fetchAll(db)

        let iconIds = rules.map(\.iconId)
        let pairs = try Icon.fetchAll(db, keys: iconIds).map { ($0.id, $0) }
        let icons = Dictionary(uniqueKeysWithValues: pairs)

        return RewardRuleList(rules: rules, icons: icons)
    }
}
