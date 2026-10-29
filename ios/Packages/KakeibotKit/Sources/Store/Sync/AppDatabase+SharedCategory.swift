import Core
import GRDB

extension AppDatabase {
    static func fitCategory(
        of entry: inout Entry,
        in db: Database
    ) throws {
        guard
            let categoryId = entry.categoryId,
            let category = try EntryCategory.fetchOne(db, key: categoryId)
        else {
            return
        }

        let isShared = try isSharedWallet(entry.walletId.description, in: db)
        let target = isShared ? entry.walletId.description : nil

        guard category.walletId?.description != target else {
            return
        }

        let fitted: String

        if let matched = try matchingCategory(of: category, in: target, db: db) {
            fitted = matched
        } else if let target {
            fitted = try copyCategory(categoryId.description, to: target, in: db).category
        } else {
            return
        }

        let tagID = try entry.tagId.flatMap { tagId in
            try fittingTag(tagId.description, to: fitted, copying: isShared, in: db)
        }

        entry.categoryId = EntryCategory.ID(fitted)
        entry.tagId = tagID.flatMap(EntryTag.ID.init)
    }

    static func isSharedWallet(
        _ walletID: String,
        in db: Database
    ) throws -> Bool {
        try Bool.fetchOne(
            db,
            sql: "SELECT EXISTS (SELECT 1 FROM sync_share WHERE wallet_id = ?)",
            arguments: [walletID]
        ) ?? false
    }
}

private extension AppDatabase {
    static func matchingCategory(
        of category: EntryCategory,
        in walletID: String?,
        db: Database
    ) throws -> String? {
        try String.fetchOne(
            db,
            sql: """
            SELECT id FROM category
            WHERE wallet_id IS ? AND kind = ? AND name = ?
            ORDER BY archived_at IS NOT NULL, sort_order
            LIMIT 1
            """,
            arguments: [walletID, category.kind.rawValue, category.name]
        )
    }

    static func fittingTag(
        _ tagID: String,
        to categoryID: String,
        copying: Bool,
        in db: Database
    ) throws -> String? {
        let matched = try String.fetchOne(
            db,
            sql: """
            SELECT tag.id FROM tag
            JOIN tag AS original ON original.name = tag.name
            WHERE original.id = ? AND tag.category_id = ?
            ORDER BY tag.archived_at IS NOT NULL, tag.sort_order
            LIMIT 1
            """,
            arguments: [tagID, categoryID]
        )

        guard
            matched == nil,
            copying
        else {
            return matched
        }

        return try copyTag(tagID, to: categoryID, in: db)
    }
}
