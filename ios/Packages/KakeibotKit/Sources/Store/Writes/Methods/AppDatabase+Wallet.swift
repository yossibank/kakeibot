import Core
import Foundation
import GRDB

public extension AppDatabase {
    enum WalletWriteError: Error, Equatable {
        case walletNotFound
        case iconNotFound
        case lastShownWallet
        case hasEntries
    }
}

public extension AppDatabase {
    @discardableResult
    func deleteWallet(
        _ id: Wallet.ID,
        at now: Date
    ) async throws -> Deletion {
        try await writer.write { db in
            let wallet = try Self.deletableWallet(id, in: db)

            let recurrings = Recurring.filter(
                Column("wallet_id") == id || Column("to_wallet_id") == id
            )

            let templates = EntryTemplate.filter(Column("wallet_id") == id)
            let valuations = Valuation.filter(Column("wallet_id") == id)
            let adjustments = Adjustment.filter(Column("wallet_id") == id)
            let categories = EntryCategory.filter(Column("wallet_id") == id)
            let deletedCategories = try categories.fetchAll(db)
            let categoryIds = deletedCategories.map(\.id)
            let iconIds = deletedCategories.map(\.iconId) + [wallet.iconId]
            let tags = EntryTag.filter(categoryIds.contains(Column("category_id")))
            let icons = Icon.filter(iconIds.contains(Column("id")))
            let iconRecords = try icons.fetchAll(db)
            let tagRecords = try tags.fetchAll(db)
            let recurringRecords = try recurrings.fetchAll(db)
            let templateRecords = try templates.fetchAll(db)
            let valuationRecords = try valuations.fetchAll(db)
            let adjustmentRecords = try adjustments.fetchAll(db)

            let deletion = Deletion(
                icons: iconRecords,
                wallets: [wallet],
                categories: deletedCategories,
                tags: tagRecords,
                recurrings: recurringRecords,
                templates: templateRecords,
                valuations: valuationRecords,
                adjustments: adjustmentRecords
            )

            let key = SyncKey(table: .wallet, id: id.description)
            let isShared = try Self.syncSharedWallet(for: key, in: db) != nil

            try Self.deleteRecurrings(recurrings, in: db, at: now)
            try templates.deleteAll(db)
            try valuations.deleteAll(db)
            try adjustments.deleteAll(db)
            try tags.deleteAll(db)
            try categories.deleteAll(db)
            try wallet.delete(db)
            try icons.deleteAll(db)

            if isShared {
                try Self.queue(key, in: db)
            }

            return deletion
        }
    }
}

extension AppDatabase {
    static func hasValuations(
        of id: Wallet.ID,
        in db: Database
    ) throws -> Bool {
        try Valuation.filter(Column("wallet_id") == id).fetchCount(db) > 0
    }

    static func hasRecords(
        of id: Wallet.ID,
        in db: Database
    ) throws -> Bool {
        let walletColumns = Column("wallet_id") == id || Column("to_wallet_id") == id
        let hasEntries = try Entry.filter(walletColumns).fetchCount(db) > 0
        let hasRecurrings = try Recurring.filter(walletColumns).fetchCount(db) > 0
        let hasAdjustments = try Adjustment.filter(Column("wallet_id") == id).fetchCount(db) > 0
        return try hasEntries || hasRecurrings || hasAdjustments || hasValuations(of: id, in: db)
    }

    static func shownWalletCount(in db: Database) throws -> Int {
        try Wallet.filter(Column("archived_at") == nil).fetchCount(db)
    }
}

private extension AppDatabase {
    static func deletableWallet(
        _ id: Wallet.ID,
        in db: Database
    ) throws -> Wallet {
        guard let wallet = try Wallet.fetchOne(db, key: id) else {
            throw WalletWriteError.walletNotFound
        }

        let entries = Entry.filter(Column("wallet_id") == id || Column("to_wallet_id") == id)

        if try entries.fetchCount(db) > 0 {
            throw WalletWriteError.hasEntries
        }

        if wallet.archivedAt == nil,
           try shownWalletCount(in: db) <= 1 {
            throw WalletWriteError.lastShownWallet
        }

        return wallet
    }
}
