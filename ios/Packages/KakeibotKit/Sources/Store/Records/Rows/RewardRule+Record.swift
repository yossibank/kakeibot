import Core
import Foundation
import GRDB

extension RewardRule: StoreRecord {
    public static let databaseTableName = "reward_rule"
}

extension RewardRule: HidableRecord {
    static var notFound: any Error {
        AppDatabase.RewardRuleWriteError.ruleNotFound
    }

    static func setHidden(
        _ id: ID,
        _ isHidden: Bool,
        in db: Database,
        at now: Date
    ) throws {
        guard var rule = try fetchOne(db, key: id) else {
            throw notFound
        }

        rule.isActive = !isHidden
        rule.updatedAt = now
        try rule.update(db)
    }
}

extension RewardRule: IconBackedRecord {
    static var iconNotFound: any Error {
        AppDatabase.RewardRuleWriteError.iconNotFound
    }
}

extension RewardRule: HidableRow {
    public static let ordering = OrderedRowWrite<RewardRule>.sortable
    public static let hiding = HidableRowWrite<RewardRule>.hidable
}
