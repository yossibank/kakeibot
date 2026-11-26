import Core
import Foundation
import GRDB

public extension AppDatabase {
    enum RewardRuleWriteError: Error, Equatable {
        case ruleNotFound
        case iconNotFound
        case hasLogs
        case shortOfBalance
        case isHidden
    }
}

public extension AppDatabase {
    @discardableResult
    func deleteRewardRule(_ id: RewardRule.ID) async throws -> Deletion {
        try await writer.write { db in
            guard let rule = try RewardRule.fetchOne(db, key: id) else {
                throw RewardRuleWriteError.ruleNotFound
            }

            let logs = RewardLog.filter(Column("rule_id") == id)

            guard try logs.fetchCount(db) == 0 else {
                throw RewardRuleWriteError.hasLogs
            }

            let deletion = Deletion(rewardRules: [rule])

            try rule.delete(db)

            return deletion
        }
    }
}
