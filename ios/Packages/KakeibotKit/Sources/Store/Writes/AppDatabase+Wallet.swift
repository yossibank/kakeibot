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
            try Wallet.reorder(
                ids,
                orThrow: WalletWriteError.walletNotFound,
                in: db,
                at: now
            )
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

            if isHidden, try Self.shownWalletCount(in: db) <= 1 {
                throw WalletWriteError.lastShownWallet
            }

            wallet.archivedAt = isHidden ? now : nil
            wallet.updatedAt = now
            try wallet.update(db)
        }
    }

    func deleteWallet(_ id: Wallet.ID) async throws {
        try await writer.write { db in
            guard let wallet = try Wallet.fetchOne(db, key: id) else {
                throw WalletWriteError.walletNotFound
            }

            let entries = Entry.filter(
                Column("wallet_id") == id || Column("to_wallet_id") == id
            )

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

            try Self.deleteRecurrings(recurrings, in: db)

            try EntryTemplate
                .filter(Column("wallet_id") == id)
                .deleteAll(db)

            try Valuation
                .filter(Column("wallet_id") == id)
                .deleteAll(db)

            try wallet.delete(db)
        }
    }
}

extension AppDatabase {
    static func deleteRecurrings(
        _ recurrings: QueryInterfaceRequest<Recurring>,
        in db: Database
    ) throws {
        let ids = try recurrings.fetchAll(db).map(\.id)

        try Entry
            .filter(ids.contains(Column("recurring_id")))
            .updateAll(
                db,
                Column("recurring_id").set(to: nil),
                Column("recurring_date").set(to: nil)
            )

        try recurrings.deleteAll(db)
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

        let wallet = try draft.newWallet(
            iconId: icon.id,
            sortOrder: sortOrder,
            at: now
        )

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

        let wallet = try draft.applied(to: existing, at: now)
        try draft.applied(to: icon, at: now).update(db)
        try wallet.update(db)
        return wallet
    }

    static func shownWalletCount(in db: Database) throws -> Int {
        try Wallet
            .filter(Column("archived_at") == nil)
            .fetchCount(db)
    }
}
