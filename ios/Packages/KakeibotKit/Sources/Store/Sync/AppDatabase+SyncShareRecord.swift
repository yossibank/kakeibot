import Core
import Foundation
import GRDB

public extension AppDatabase {
    func syncRecord(for id: SyncRecordID) async throws -> SyncRecord? {
        try await writer.read { db in
            guard let row = try Self.localRow(for: id.key, in: db) else {
                return nil
            }

            let record = SyncRecord(key: id.key, row: row)

            guard let walletID = SyncZone.walletID(of: id.zoneName) else {
                return record
            }

            let shared = record.removingLocalColumns()

            guard try Self.isForeignWallet(walletID, in: db) else {
                return shared
            }

            return try Self.sentTransfer(shared, in: walletID, db: db) ?? shared
        }
    }
}

extension AppDatabase {
    static func sharedKeys(in systemFields: [SyncRecordID: Data]) -> Set<SyncKey> {
        let ids = systemFields.keys.filter { SyncZone.walletID(of: $0.zoneName) != nil }
        return Set(ids.map(\.key))
    }

    static func receivedTransfer(
        _ record: SyncRecord,
        in db: Database
    ) throws -> SyncRecord {
        guard record.key.table == .entry else {
            return record
        }

        if let local = try localRow(for: record.key, in: db),
           local["type"] == Entry.Kind.transfer.rawValue,
           try isTransferView(record, in: db) {
            return record.keeping(transferColumns, of: local)
        }

        guard let walletID = try receivingWallet(of: record, in: db) else {
            return record
        }

        try setApplying(false, in: db)

        let view = try transferView(of: record, in: walletID, creating: true, db: db)

        try setApplying(true, in: db)

        return view ?? record
    }

    static func isForeignWallet(
        _ walletID: Wallet.ID,
        in db: Database
    ) throws -> Bool {
        try Bool.fetchOne(
            db,
            sql: """
            SELECT EXISTS (
                SELECT 1 FROM sync_share WHERE wallet_id = ? AND owner_name IS NOT NULL
            )
            """,
            arguments: [walletID.description]
        ) ?? false
    }

    static func prepareSharedTransfer(
        _ entry: Entry,
        in db: Database,
        at now: Date
    ) throws {
        guard let toWalletId = entry.toWalletId else {
            return
        }

        let sides: [(Wallet.ID, EntryCategory.Kind)] = [
            (entry.walletId, .expense),
            (toWalletId, .income)
        ]

        for (walletID, kind) in sides where try isForeignWallet(walletID, in: db) {
            _ = try transferCategoryId(kind, ofWallet: walletID, in: db, at: now)
        }
    }
}

extension SyncRecord {
    init(
        key: SyncKey,
        row: Row
    ) {
        let pairs = row.columnNames.map { ($0, SyncValue(row[$0])) }
        let values = Dictionary(uniqueKeysWithValues: pairs)

        self.init(key: key, values: values)
    }

    func keeping(
        _ columns: Set<String>,
        of row: Row
    ) -> SyncRecord {
        var values = values

        for column in columns {
            values[column] = SyncValue(row[column])
        }

        return SyncRecord(key: key, values: values)
    }

    func removingLocalColumns() -> SyncRecord {
        removing(key.table.localColumns)
    }

    func removing(_ columns: Set<String>) -> SyncRecord {
        guard !columns.isEmpty else {
            return self
        }

        let kept = values.filter { !columns.contains($0.key) }

        return SyncRecord(key: key, values: kept)
    }
}

private extension AppDatabase {
    static let transferColumns: Set = [
        "type",
        "wallet_id",
        "to_wallet_id",
        "category_id",
        "tag_id",
        "bill_month"
    ]

    static func sentTransfer(
        _ record: SyncRecord,
        in walletID: Wallet.ID,
        db: Database
    ) throws -> SyncRecord? {
        let others = [record.values["wallet_id"], record.values["to_wallet_id"]]
            .compactMap(\.self)
            .filter { $0 != .text(walletID.description) }

        for case let .text(other) in others where try isSharedWallet(other, in: db) {
            return nil
        }

        return try transferView(of: record, in: walletID, creating: false, db: db)
    }

    static func receivingWallet(
        of record: SyncRecord,
        in db: Database
    ) throws -> Wallet.ID? {
        guard
            record.values["type"] == .text(Entry.Kind.transfer.rawValue),
            case let .text(from) = record.values["wallet_id"],
            case let .text(to) = record.values["to_wallet_id"]
        else {
            return nil
        }

        let hasFrom = try hasWallet(from, in: db)
        let hasTo = try hasWallet(to, in: db)

        guard
            hasFrom != hasTo,
            let walletID = Wallet.ID(hasFrom ? from : to),
            try isForeignWallet(walletID, in: db)
        else {
            return nil
        }

        return walletID
    }

    static func isTransferView(
        _ record: SyncRecord,
        in db: Database
    ) throws -> Bool {
        guard
            case let .text(type) = record.values["type"],
            let kind = EntryCategory.Kind(rawValue: type),
            case let .text(wallet) = record.values["wallet_id"],
            let walletID = Wallet.ID(wallet),
            let categoryID = try existingTransferCategoryId(kind, ofWallet: walletID, in: db)
        else {
            return false
        }

        return record.values["category_id"] == .text(categoryID.description)
    }

    static func transferView(
        of record: SyncRecord,
        in walletID: Wallet.ID,
        creating: Bool,
        db: Database
    ) throws -> SyncRecord? {
        let wallet = SyncValue.text(walletID.description)

        guard record.values["type"] == .text(Entry.Kind.transfer.rawValue) else {
            return nil
        }

        let kind: EntryCategory.Kind

        if record.values["wallet_id"] == wallet {
            kind = .expense
        } else if record.values["to_wallet_id"] == wallet {
            kind = .income
        } else {
            return nil
        }

        let categoryID: EntryCategory.ID? = if creating {
            try transferCategoryId(kind, ofWallet: walletID, in: db, at: Date())
        } else {
            try existingTransferCategoryId(kind, ofWallet: walletID, in: db)
        }

        guard let categoryID else {
            return nil
        }

        var values = record.values
        values["type"] = .text(kind.rawValue)
        values["wallet_id"] = wallet
        values["to_wallet_id"] = .null
        values["category_id"] = .text(categoryID.description)
        values["tag_id"] = .null
        values["bill_month"] = .null

        return SyncRecord(key: record.key, values: values)
    }

    static func hasWallet(
        _ id: String,
        in db: Database
    ) throws -> Bool {
        try Bool.fetchOne(
            db,
            sql: "SELECT EXISTS (SELECT 1 FROM wallet WHERE id = ?)",
            arguments: [id]
        ) ?? false
    }
}

private extension SyncTable {
    var localColumns: Set<String> {
        switch self {
        case .entry: ["template_id", "recurring_id", "recurring_date"]
        default: []
        }
    }
}
