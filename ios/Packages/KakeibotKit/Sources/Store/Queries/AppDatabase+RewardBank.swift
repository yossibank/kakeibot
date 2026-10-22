import Core
import GRDB

public extension AppDatabase {
    func rewardBankUpdates() -> some AsyncSequence<RewardBank, any Error> {
        ValueObservation
            .tracking(Self.rewardBank)
            .values(in: writer)
    }

    func rewardBank() async throws -> RewardBank {
        try await writer.read(Self.rewardBank)
    }
}

private extension AppDatabase {
    static func rewardBank(in db: Database) throws -> RewardBank {
        let rules = try RewardRule
            .order(RewardRule.sortOrder, Column("created_at"))
            .fetchAll(db)

        let iconIds = rules.map(\.iconId)
        let pairs = try Icon.fetchAll(db, keys: iconIds).map { ($0.id, $0) }

        let logs = try RewardLog
            .order(Column("date").desc, Column("created_at").desc)
            .fetchAll(db)

        return try RewardBank(
            rules: rules,
            icons: Dictionary(uniqueKeysWithValues: pairs),
            logs: logs,
            goals: RewardGoal.fetchAll(db)
        )
    }
}
