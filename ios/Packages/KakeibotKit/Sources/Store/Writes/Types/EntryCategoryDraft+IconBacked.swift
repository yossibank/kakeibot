import Core
import Foundation
import GRDB

extension EntryCategoryDraft: IconBackedDraft {
    func newRecord(
        iconId: Icon.ID,
        sortOrder: Int,
        at now: Date
    ) throws -> EntryCategory {
        try newCategory(iconId: iconId, sortOrder: sortOrder, at: now)
    }

    func sortOrder(in db: Database) throws -> Int {
        let sameKind = EntryCategory
            .filter(Column("kind") == kind.rawValue)
            .filter(Column("wallet_id") == nil)

        return try EntryCategory.nextSortOrder(of: sameKind, in: db)
    }
}
