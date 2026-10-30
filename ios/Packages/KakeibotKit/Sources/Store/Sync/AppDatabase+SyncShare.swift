import Core
import Foundation
import GRDB

public extension AppDatabase {
    func syncSharedWallet(for key: SyncKey) async throws -> Wallet.ID? {
        try await writer.read { db in
            try Self.syncSharedWallet(for: key, in: db)
        }
    }

    func startSharing(_ walletID: Wallet.ID) async throws {
        try await writer.write { db in
            try Self.startSharing(walletID.description, in: db)
        }
    }

    func endSharing(
        _ walletID: Wallet.ID,
        at now: Date = Date()
    ) async throws {
        try await writer.write { db in
            try Self.endSharing(walletID, in: db, at: now)
        }
    }

    func walletShareUpdates() -> some AsyncSequence<[WalletShare], any Error> {
        ValueObservation
            .tracking { db in
                try Self.walletShares(in: db)
            }
            .removeDuplicates()
            .values(in: writer)
    }

    func joinedShareUpdates() -> some AsyncSequence<[JoinedShare], any Error> {
        ValueObservation
            .tracking { db in
                try Self.joinedShares(in: db)
            }
            .removeDuplicates()
            .values(in: writer)
    }
}

extension AppDatabase {
    static func syncSharedWallet(
        for key: SyncKey,
        in db: Database
    ) throws -> Wallet.ID? {
        for candidate in try shareCandidates(for: key, in: db) {
            let isShared = try Bool.fetchOne(
                db,
                sql: "SELECT EXISTS (SELECT 1 FROM sync_share WHERE wallet_id = ?)",
                arguments: [candidate]
            ) ?? false

            if isShared {
                return Wallet.ID(candidate)
            }
        }

        return nil
    }

    static func notifyShareChanges(in db: Database) throws {
        try db.notifyChanges(in: Table("sync_share"))
    }
}

private extension AppDatabase {
    static func walletShares(in db: Database) throws -> [WalletShare] {
        let rows = try Row.fetchAll(
            db,
            sql: """
            SELECT wallet.*, sync_share.wallet_id IS NOT NULL AS is_shared FROM wallet
            LEFT JOIN sync_share ON sync_share.wallet_id = wallet.id
            WHERE sync_share.owner_name IS NULL
                AND (wallet.archived_at IS NULL OR sync_share.wallet_id IS NOT NULL)
            ORDER BY wallet.sort_order, wallet.created_at
            """
        )

        let wallets = try rows.map { try Wallet(row: $0) }
        let iconIds = wallets.map(\.iconId)
        let icons = try Icon.fetchAll(db, keys: iconIds)
        let iconPairs = icons.map { ($0.id, $0) }
        let iconsByID = Dictionary(uniqueKeysWithValues: iconPairs)

        return zip(wallets, rows).map { wallet, row in
            WalletShare(wallet: wallet, icon: iconsByID[wallet.iconId], isShared: row["is_shared"])
        }
    }

    static func joinedShares(in db: Database) throws -> [JoinedShare] {
        let rows = try Row.fetchAll(
            db,
            sql: """
            SELECT wallet.*, sync_share.owner_name AS share_owner FROM wallet
            JOIN sync_share ON sync_share.wallet_id = wallet.id
            WHERE sync_share.owner_name IS NOT NULL
            ORDER BY wallet.sort_order, wallet.created_at
            """
        )

        let wallets = try rows.map { try Wallet(row: $0) }
        let iconIds = wallets.map(\.iconId)
        let icons = try Icon.fetchAll(db, keys: iconIds)
        let iconPairs = icons.map { ($0.id, $0) }
        let iconsByID = Dictionary(uniqueKeysWithValues: iconPairs)

        return zip(wallets, rows).map { wallet, row in
            JoinedShare(
                wallet: wallet,
                icon: iconsByID[wallet.iconId],
                ownerName: row["share_owner"]
            )
        }
    }

    static func shareCandidates(
        for key: SyncKey,
        in db: Database
    ) throws -> [String] {
        switch key.table {
        case .wallet:
            return [key.id]

        case .valuation:
            return try walletColumns("SELECT wallet_id FROM valuation WHERE id = ?", key.id, in: db)

        case .entry:
            return try walletColumns(
                "SELECT wallet_id, to_wallet_id FROM entry WHERE id = ?",
                key.id,
                in: db
            )

        case .category:
            return try walletColumns("SELECT wallet_id FROM category WHERE id = ?", key.id, in: db)

        case .tag:
            return try walletColumns(
                """
                SELECT category.wallet_id FROM tag
                JOIN category ON category.id = tag.category_id
                WHERE tag.id = ?
                """,
                key.id,
                in: db
            )

        case .icon:
            let wallets = try String.fetchAll(
                db,
                sql: "SELECT id FROM wallet WHERE icon_id = ? ORDER BY id",
                arguments: [key.id]
            )

            let categories = try String.fetchAll(
                db,
                sql: """
                SELECT wallet_id FROM category
                WHERE icon_id = ? AND wallet_id IS NOT NULL
                ORDER BY wallet_id
                """,
                arguments: [key.id]
            )

            return wallets + categories

        default:
            return []
        }
    }

    static func walletColumns(
        _ sql: String,
        _ id: String,
        in db: Database
    ) throws -> [String] {
        guard let row = try Row.fetchOne(db, sql: sql, arguments: [id]) else {
            return []
        }

        return row.columnNames.compactMap { row[$0] as String? }
    }

    static func startSharing(
        _ walletID: String,
        in db: Database
    ) throws {
        try db.execute(
            sql: """
            INSERT INTO sync_share (wallet_id, owner_name) VALUES (?, NULL)
            ON CONFLICT DO NOTHING
            """,
            arguments: [walletID]
        )

        guard db.changesCount > 0 else {
            return
        }

        try notifyShareChanges(in: db)

        let copied = try copyOwnCategories(for: walletID, in: db)

        try moveEntries(of: walletID, to: copied, in: db)

        let keys = try keysOfWallet(walletID, in: db) + copied.keys

        for key in keys {
            try queue(key, in: db)
        }
    }

    static func endSharing(
        _ walletID: Wallet.ID,
        in db: Database,
        at now: Date
    ) throws {
        let id = walletID.description
        let zoneName = SyncZone.wallet(walletID)

        let isOwner = try Bool.fetchOne(
            db,
            sql: "SELECT owner_name IS NULL FROM sync_share WHERE wallet_id = ?",
            arguments: [id]
        ) ?? true

        try db.execute(sql: "DELETE FROM sync_share WHERE wallet_id = ?", arguments: [id])
        try notifyShareChanges(in: db)
        try db.execute(sql: "DELETE FROM sync_record WHERE zone_name = ?", arguments: [zoneName])

        let isEnabled = try Bool.fetchOne(db, sql: "SELECT enabled FROM sync_state") ?? false

        let hasWallet = try Bool.fetchOne(
            db,
            sql: "SELECT EXISTS (SELECT 1 FROM wallet WHERE id = ?)",
            arguments: [id]
        ) ?? false

        guard hasWallet else {
            return
        }

        guard isOwner else {
            let keys = try keysOfWallet(id, in: db) + categoryKeys(ofWallet: id, in: db)

            for key in keys {
                try db.execute(
                    sql: "DELETE FROM sync_change WHERE table_name = ? AND record_id = ?",
                    arguments: [key.table.rawValue, key.id]
                )
            }

            try leaveSharedWallet(id, in: db, at: now)
            try db.notifyChanges(in: Table("sync_change"))
            return
        }

        try returnSharedCategories(of: id, in: db)

        guard isEnabled else {
            return
        }

        for key in try keysOfWallet(id, in: db) {
            try queue(key, in: db)
        }
    }

    static func categoryKeys(
        ofWallet walletID: String,
        in db: Database
    ) throws -> [SyncKey] {
        let categories = try String.fetchAll(
            db,
            sql: "SELECT id FROM category WHERE wallet_id = ?",
            arguments: [walletID]
        )

        let tags = try String.fetchAll(
            db,
            sql: """
            SELECT tag.id FROM tag JOIN category ON category.id = tag.category_id
            WHERE category.wallet_id = ?
            """,
            arguments: [walletID]
        )

        let icons = try String.fetchAll(
            db,
            sql: "SELECT icon_id FROM category WHERE wallet_id = ?",
            arguments: [walletID]
        )

        return categories.map { SyncKey(table: .category, id: $0) }
            + tags.map { SyncKey(table: .tag, id: $0) }
            + icons.map { SyncKey(table: .icon, id: $0) }
    }

    static func keysOfWallet(
        _ walletID: String,
        in db: Database
    ) throws -> [SyncKey] {
        let icons = try String.fetchAll(
            db,
            sql: "SELECT icon_id FROM wallet WHERE id = ?",
            arguments: [walletID]
        )

        let valuations = try String.fetchAll(
            db,
            sql: "SELECT id FROM valuation WHERE wallet_id = ?",
            arguments: [walletID]
        )

        let entries = try String.fetchAll(
            db,
            sql: "SELECT id FROM entry WHERE wallet_id = ?1 OR to_wallet_id = ?1",
            arguments: [walletID]
        )

        return [SyncKey(table: .wallet, id: walletID)]
            + icons.map { SyncKey(table: .icon, id: $0) }
            + valuations.map { SyncKey(table: .valuation, id: $0) }
            + entries.map { SyncKey(table: .entry, id: $0) }
    }
}
