import Core
import Foundation
import GRDB

extension AppDatabase {
    static func leaveSharedWallet(
        _ walletID: String,
        in db: Database,
        at now: Date
    ) throws {
        try keepTransfers(of: walletID, in: db, at: now)
        try removeSharedWallet(walletID, in: db, at: now)
    }
}

private extension AppDatabase {
    static let walletCategories = "SELECT id FROM category WHERE wallet_id = ?1"
    static let foreignWallets = "SELECT wallet_id FROM sync_share WHERE owner_name IS NOT NULL"

    static let outgoing = """
    type = 'transfer' AND to_wallet_id = ?1 AND wallet_id NOT IN (\(foreignWallets))
    """

    static let incoming = """
    type = 'transfer' AND wallet_id = ?1 AND to_wallet_id NOT IN (\(foreignWallets))
    """

    static func keepTransfers(
        of walletID: String,
        in db: Database,
        at now: Date
    ) throws {
        let stamp = now.formatted(.iso8601)

        if try hasEntries(where: outgoing, of: walletID, in: db) {
            let category = try transferCategoryId(.expense, in: db, at: now)

            try db.execute(
                sql: """
                UPDATE entry SET transfer_id = NULL, updated_at = ?2
                WHERE transfer_id IN (SELECT id FROM entry WHERE \(outgoing))
                """,
                arguments: [walletID, stamp]
            )

            try db.execute(
                sql: """
                UPDATE entry
                SET type = 'expense', to_wallet_id = NULL, category_id = ?2, updated_at = ?3
                WHERE \(outgoing)
                """,
                arguments: [walletID, category.description, stamp]
            )
        }

        if try hasEntries(where: incoming, of: walletID, in: db) {
            let category = try transferCategoryId(.income, in: db, at: now)

            try db.execute(
                sql: """
                UPDATE entry
                SET type = 'income', wallet_id = to_wallet_id, to_wallet_id = NULL,
                    category_id = ?2, updated_at = ?3
                WHERE \(incoming)
                """,
                arguments: [walletID, category.description, stamp]
            )
        }
    }

    static func hasEntries(
        where condition: String,
        of walletID: String,
        in db: Database
    ) throws -> Bool {
        try Bool.fetchOne(
            db,
            sql: "SELECT EXISTS (SELECT 1 FROM entry WHERE \(condition))",
            arguments: [walletID]
        ) ?? false
    }

    static func removeSharedWallet(
        _ walletID: String,
        in db: Database,
        at now: Date
    ) throws {
        let icons = try String.fetchAll(
            db,
            sql: """
            SELECT icon_id FROM wallet WHERE id = ?1
            UNION SELECT icon_id FROM category WHERE wallet_id = ?1
            """,
            arguments: [walletID]
        )

        let categories = try String.fetchAll(db, sql: walletCategories, arguments: [walletID])

        let recurrings = Recurring.filter(
            Column("wallet_id") == walletID
                || Column("to_wallet_id") == walletID
                || categories.contains(Column("category_id"))
        )

        let entries = Entry.filter(
            Column("wallet_id") == walletID || Column("to_wallet_id") == walletID
        )

        try detachRewardGoals(from: entries.fetchAll(db).map(\.id), in: db, at: now)

        try setApplying(true, in: db)
        _ = try entries.deleteAll(db)
        try setApplying(false, in: db)

        _ = try deleteRecurrings(recurrings, in: db, at: now)

        try db.execute(
            sql: """
            DELETE FROM template
            WHERE wallet_id = ?1 OR category_id IN (\(walletCategories))
            """,
            arguments: [walletID]
        )

        try db.execute(
            sql: "DELETE FROM budget WHERE category_id IN (\(walletCategories))",
            arguments: [walletID]
        )

        try setApplying(true, in: db)

        for sql in [
            "DELETE FROM valuation WHERE wallet_id = ?1",
            "DELETE FROM tag WHERE category_id IN (\(walletCategories))",
            "DELETE FROM category WHERE wallet_id = ?1",
            "DELETE FROM wallet WHERE id = ?1"
        ] {
            try db.execute(sql: sql, arguments: [walletID])
        }

        try Icon.filter(icons.contains(Column("id"))).deleteAll(db)
        try setApplying(false, in: db)
    }
}
