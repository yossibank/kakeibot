import Core
import Foundation
import GRDB

public extension AppDatabase {
    func setReward(
        _ ruleId: RewardRule.ID,
        isAchieved: Bool,
        on date: LocalDate,
        at now: Date
    ) async throws {
        try await writer.write { db in
            guard let rule = try RewardRule.fetchOne(db, key: ruleId) else {
                throw RewardRuleWriteError.ruleNotFound
            }

            let saved = RewardLog.filter(Column("rule_id") == ruleId).filter(Column("date") == date)

            guard isAchieved else {
                let cleared = try saved.fetchAll(db).reduce(0) { $0 + $1.amount }
                let logs = try RewardLog.fetchAll(db)
                let goals = try RewardGoal.fetchAll(db)
                let balance = RewardBalance.amount(logs: logs, goals: goals)

                guard balance - cleared >= 0 else {
                    throw RewardRuleWriteError.shortOfBalance
                }

                try saved.deleteAll(db)

                return
            }

            guard try saved.fetchCount(db) == 0 else {
                return
            }

            guard rule.isActive else {
                throw RewardRuleWriteError.isHidden
            }

            let log = RewardLog(ruleId: rule.id, date: date, amount: rule.amount, createdAt: now)

            try log.insert(db)
        }
    }
}
