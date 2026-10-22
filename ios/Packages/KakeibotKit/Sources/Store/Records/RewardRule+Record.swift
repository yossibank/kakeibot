import Core
import GRDB

extension RewardRule: StoreRecord {
    public static let databaseTableName = "reward_rule"
}

extension RewardRule: SortableRecord {}
