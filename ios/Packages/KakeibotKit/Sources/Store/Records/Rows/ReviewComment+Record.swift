import Core
import GRDB

extension ReviewComment: StoreRecord {
    public static let databaseTableName = "review_comment"
}
