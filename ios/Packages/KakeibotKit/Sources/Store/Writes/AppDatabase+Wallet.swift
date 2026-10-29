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

    @discardableResult
    func saveWallet(
        _ draft: WalletDraft,
        editing id: Wallet.ID? = nil,
        at now: Date
    ) async throws -> Wallet {
        try await writer.write { db in
            if let id {
                try Self.updateWallet(id, with: draft, in: db, at: now)
            } else {
                try Self.insertWallet(draft, into: db, at: now)
            }
        }
    }

    func reorderWallets(
        _ ids: [Wallet.ID],
        at now: Date
    ) async throws {
        try await writer.write { db in
            try Wallet.reorder(ids, orThrow: WalletWriteError.walletNotFound, in: db, at: now)
        }
    }

    func setWalletHidden(
        _ id: Wallet.ID,
        isHidden: Bool,
        at now: Date
    ) async throws {
        try await writer.write { db in
            guard var wallet = try Wallet.fetchOne(db, key: id) else {
                throw WalletWriteError.walletNotFound
            }

            if isHidden,
               try Self.shownWalletCount(in: db) <= 1 {
                throw WalletWriteError.lastShownWallet
            }

            wallet.archivedAt = isHidden ? now : nil
            wallet.updatedAt = now

            try wallet.update(db)
        }
    }

    @discardableResult
    func deleteWallet(
        _ id: Wallet.ID,
        at now: Date
    ) async throws -> Deletion {
        try await writer.write { db in
            guard let wallet = try Wallet.fetchOne(db, key: id) else {
                throw WalletWriteError.walletNotFound
            }

            let entries = Entry.filter(Column("wallet_id") == id || Column("to_wallet_id") == id)

            if try entries.fetchCount(db) > 0 {
                throw WalletWriteError.hasEntries
            }

            if wallet.archivedAt == nil,
               try Self.shownWalletCount(in: db) <= 1 {
                throw WalletWriteError.lastShownWallet
            }

            let recurrings = Recurring.filter(
                Column("wallet_id") == id || Column("to_wallet_id") == id
            )

            let templates = EntryTemplate.filter(Column("wallet_id") == id)
            let valuations = Valuation.filter(Column("wallet_id") == id)
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

            let deletion = Deletion(
                icons: iconRecords,
                wallets: [wallet],
                categories: deletedCategories,
                tags: tagRecords,
                recurrings: recurringRecords,
                templates: templateRecords,
                valuations: valuationRecords
            )

            let key = SyncKey(table: .wallet, id: id.description)
            let isShared = try Self.syncSharedWallet(for: key, in: db) != nil

            try Self.deleteRecurrings(recurrings, in: db, at: now)
            try templates.deleteAll(db)
            try valuations.deleteAll(db)
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

private extension AppDatabase {
    static func insertWallet(
        _ draft: WalletDraft,
        into db: Database,
        at now: Date
    ) throws -> Wallet {
        let icon = try draft.newIcon(at: now)
        let sortOrder = try Wallet.nextSortOrder(in: db)

        let wallet = try draft.newWallet(iconId: icon.id, sortOrder: sortOrder, at: now)

        try icon.insert(db)
        try wallet.insert(db)

        return wallet
    }

    static func updateWallet(
        _ id: Wallet.ID,
        with draft: WalletDraft,
        in db: Database,
        at now: Date
    ) throws -> Wallet {
        guard let existing = try Wallet.fetchOne(db, key: id) else {
            throw WalletWriteError.walletNotFound
        }

        guard let icon = try Icon.fetchOne(db, key: existing.iconId) else {
            throw WalletWriteError.iconNotFound
        }

        let hasRecords = try Self.hasRecords(of: id, in: db)
        let hasValuations = try Self.hasValuations(of: id, in: db)

        let locked = draft.locked(
            by: existing,
            hasRecords: hasRecords,
            hasValuations: hasValuations
        )

        let wallet = try locked.applied(to: existing, at: now)

        try draft.applied(to: icon, at: now).update(db)
        try wallet.update(db)

        return wallet
    }

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

        return try hasEntries || hasRecurrings || hasValuations(of: id, in: db)
    }

    static func shownWalletCount(in db: Database) throws -> Int {
        try Wallet.filter(Column("archived_at") == nil).fetchCount(db)
    }
}
