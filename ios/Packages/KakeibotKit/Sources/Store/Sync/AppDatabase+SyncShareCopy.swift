import Core
import Foundation
import GRDB

extension AppDatabase {
    struct Copied {
        var categories: [String: String] = [:]
        var tags: [String: String] = [:]
        var keys: [SyncKey] = []
    }

    static func copyOwnCategories(
        for walletID: String,
        in db: Database
    ) throws -> Copied {
        var copied = Copied()

        let rows = try Row.fetchAll(
            db,
            sql: """
            SELECT id, icon_id FROM category
            WHERE wallet_id IS NULL AND (
                archived_at IS NULL OR id IN (
                    SELECT category_id FROM entry WHERE wallet_id = ? OR to_wallet_id = ?
                )
            )
            ORDER BY sort_order, id
            """,
            arguments: [walletID, walletID]
        )

        for row in rows {
            let categoryID: String = row["id"]
            let iconID: String = row["icon_id"]
            let newCategoryID = EntryCategory.ID().description
            let newIconID = Icon.ID().description
            let iconKey = SyncKey(table: .icon, id: newIconID)
            let categoryKey = SyncKey(table: .category, id: newCategoryID)

            try copyRow(
                of: "icon",
                id: iconID,
                as: newIconID,
                replacing: [:],
                in: db
            )

            try copyRow(
                of: "category",
                id: categoryID,
                as: newCategoryID,
                replacing: ["icon_id": newIconID, "wallet_id": walletID],
                in: db
            )

            copied.categories[categoryID] = newCategoryID

            copied.keys.append(iconKey)
            copied.keys.append(categoryKey)

            let tags = try String.fetchAll(
                db,
                sql: """
                SELECT id FROM tag
                WHERE category_id = ? AND (
                    archived_at IS NULL OR id IN (
                        SELECT tag_id FROM entry WHERE wallet_id = ? OR to_wallet_id = ?
                    )
                )
                ORDER BY sort_order, id
                """,
                arguments: [categoryID, walletID, walletID]
            )

            for tagID in tags {
                let newTagID = EntryTag.ID().description
                let tagKey = SyncKey(table: .tag, id: newTagID)

                try copyRow(
                    of: "tag",
                    id: tagID,
                    as: newTagID,
                    replacing: ["category_id": newCategoryID],
                    in: db
                )

                copied.tags[tagID] = newTagID

                copied.keys.append(tagKey)
            }
        }

        return copied
    }

    static func moveEntries(
        of walletID: String,
        to copied: Copied,
        in db: Database
    ) throws {
        for (old, new) in copied.categories {
            try db.execute(
                sql: """
                UPDATE entry SET category_id = ?
                WHERE category_id = ? AND (wallet_id = ? OR to_wallet_id = ?)
                """,
                arguments: [new, old, walletID, walletID]
            )
        }

        for (old, new) in copied.tags {
            try db.execute(
                sql: """
                UPDATE entry SET tag_id = ?
                WHERE tag_id = ? AND (wallet_id = ? OR to_wallet_id = ?)
                """,
                arguments: [new, old, walletID, walletID]
            )
        }
    }
}

private extension AppDatabase {
    static func copyRow(
        of table: String,
        id: String,
        as newID: String,
        replacing values: [String: String],
        in db: Database
    ) throws {
        let names = try db.columns(in: table).map(\.name)

        let expressions = names.map { name in
            name == "id" || values[name] != nil ? "?" : name
        }

        let replaced = names.compactMap { name in
            name == "id" ? newID : values[name]
        }

        let boundValues = replaced + [id]
        let arguments = StatementArguments(boundValues)

        try db.execute(
            sql: """
            INSERT INTO \(table) (\(names.joined(separator: ", ")))
            SELECT \(expressions.joined(separator: ", ")) FROM \(table) WHERE id = ?
            """,
            arguments: arguments
        )
    }
}
