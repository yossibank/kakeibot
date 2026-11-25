import Core
import Store

extension AppDatabase {
    func setCategory(
        of entryId: Entry.ID,
        to categoryId: EntryCategory.ID,
        tagId: EntryTag.ID? = nil
    ) async throws {
        try await writer.write { db in
            try db.execute(
                sql: "UPDATE entry SET category_id = ?, tag_id = ? WHERE id = ?",
                arguments: [categoryId.description, tagId?.description, entryId.description]
            )
        }
    }
}
