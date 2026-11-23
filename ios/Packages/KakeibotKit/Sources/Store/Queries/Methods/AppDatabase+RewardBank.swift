import Core
import GRDB

public extension AppDatabase {
    func rewardBankUpdates() -> some AsyncSequence<RewardBank, any Error> {
        ValueObservation.tracking(Self.rewardBank).values(in: writer)
    }

    func rewardBank() async throws -> RewardBank {
        try await writer.read(Self.rewardBank)
    }
}

private extension AppDatabase {
    static func rewardBank(in db: Database) throws -> RewardBank {
        let rules = try RewardRule.order(RewardRule.sortOrder, Column("created_at")).fetchAll(db)
        let iconIds = rules.map(\.iconId)
        let icons = try Icon.byID(iconIds, in: db)
        let logs = try RewardLog.order(Column("date").desc, Column("created_at").desc).fetchAll(db)
        let goals = try RewardGoal.fetchAll(db)
        return RewardBank(rules: rules, icons: icons, logs: logs, goals: goals)
    }
}
