import Core
import GRDB

extension AppDatabase {
    static func tag(
        _ id: EntryTag.ID?,
        belongsTo categoryId: EntryCategory.ID?,
        in db: Database
    ) throws -> Bool {
        guard let id else {
            return true
        }

        let tag = try EntryTag.fetchOne(db, key: id)

        return tag?.categoryId == categoryId
    }
}
