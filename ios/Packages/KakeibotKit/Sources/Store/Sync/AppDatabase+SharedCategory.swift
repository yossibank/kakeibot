import Core
import GRDB

public extension AppDatabase {
    func returnSharedCategoriesOfUnsharedWallets() throws {
        try writer.write { db in
            let walletIDs = try String.fetchAll(
                db,
                sql: """
                SELECT DISTINCT wallet_id FROM category
                WHERE wallet_id IS NOT NULL AND wallet_id NOT IN (SELECT wallet_id FROM sync_share)
                """
            )

            for walletID in walletIDs {
                try Self.returnSharedCategories(of: walletID, in: db)
            }
        }
    }
}

extension AppDatabase {
    static func returnSharedCategories(
        of walletID: String,
        in db: Database
    ) throws {
        let categories = try EntryCategory
            .filter(Column("wallet_id") == walletID)
            .order(EntryCategory.sortOrder)
            .fetchAll(db)

        for category in categories {
            let id = category.id.description

            guard let own = try matchingCategory(of: category, in: nil, db: db) else {
                try db.execute(
                    sql: "UPDATE category SET wallet_id = NULL WHERE id = ?",
                    arguments: [id]
                )

                continue
            }

            try returnTags(of: id, to: own, in: db)
            try replaceCategory(id, with: own, in: db)
            try db.execute(sql: "DELETE FROM category WHERE id = ?", arguments: [id])
            try db.execute(
                sql: "DELETE FROM icon WHERE id = ?",
                arguments: [category.iconId.description]
            )
        }
    }

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

    static func returnTags(
        of categoryID: String,
        to ownID: String,
        in db: Database
    ) throws {
        let tagIDs = try String.fetchAll(
            db,
            sql: "SELECT id FROM tag WHERE category_id = ?",
            arguments: [categoryID]
        )

        for tagID in tagIDs {
            guard let ownTag = try fittingTag(tagID, to: ownID, copying: false, in: db) else {
                try db.execute(
                    sql: "UPDATE tag SET category_id = ? WHERE id = ?",
                    arguments: [ownID, tagID]
                )

                continue
            }

            for table in ["entry", "template"] {
                try db.execute(
                    sql: "UPDATE \(table) SET tag_id = ? WHERE tag_id = ?",
                    arguments: [ownTag, tagID]
                )
            }

            try db.execute(sql: "DELETE FROM tag WHERE id = ?", arguments: [tagID])
        }
    }

    static func replaceCategory(
        _ categoryID: String,
        with ownID: String,
        in db: Database
    ) throws {
        for table in ["entry", "recurring", "template"] {
            try db.execute(
                sql: "UPDATE \(table) SET category_id = ? WHERE category_id = ?",
                arguments: [ownID, categoryID]
            )
        }

        try db.execute(
            sql: "UPDATE OR IGNORE budget SET category_id = ? WHERE category_id = ?",
            arguments: [ownID, categoryID]
        )

        try db.execute(sql: "DELETE FROM budget WHERE category_id = ?", arguments: [categoryID])
    }
}
