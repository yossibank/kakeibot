import Core
import GRDB
@testable import Store
import Testing

struct LatestSchemaTests {
    private static let hint = Comment(
        rawValue: "enum に case を足したら、表を作り直すマイグレーションを足す"
    )

    @Test
    func walletAcceptsEveryKind() throws {
        let queue = try Self.makeQueue()

        for (index, kind) in Wallet.Kind.allCases.enumerated() {
            let accepted = try Self.accepts(queue) { db in
                try db.execute(
                    sql: Self.insertWallet,
                    arguments: [Self.id(index + 10), kind.rawValue]
                )
            }

            #expect(accepted, Self.hint)
        }

        let unknown = try Self.accepts(queue) { db in
            try db.execute(sql: Self.insertWallet, arguments: [Self.id(99), "unknown"])
        }

        #expect(!unknown)
    }

    @Test
    func categoryAcceptsEveryKind() throws {
        let queue = try Self.makeQueue()

        for (index, kind) in EntryCategory.Kind.allCases.enumerated() {
            let accepted = try Self.accepts(queue) { db in
                try db.execute(
                    sql: Self.insertCategory,
                    arguments: [Self.id(index + 10), kind.rawValue]
                )
            }

            #expect(accepted, Self.hint)
        }

        let unknown = try Self.accepts(queue) { db in
            try db.execute(sql: Self.insertCategory, arguments: [Self.id(99), "unknown"])
        }

        #expect(!unknown)
    }

    @Test
    func recurringAcceptsEveryFrequency() throws {
        let queue = try Self.makeQueue()

        for (index, frequency) in Recurring.Frequency.allCases.enumerated() {
            let month = frequency == .yearly ? 1 : nil
            let accepted = try Self.accepts(queue) { db in
                try db.execute(
                    sql: Self.insertRecurring,
                    arguments: [Self.id(index + 10), frequency.rawValue, month]
                )
            }

            #expect(accepted, Self.hint)
        }

        let unknown = try Self.accepts(queue) { db in
            try db.execute(
                sql: Self.insertRecurring,
                arguments: [Self.id(99), "unknown", nil]
            )
        }

        #expect(!unknown)
    }

    @Test
    func entryAcceptsEveryKind() throws {
        let queue = try Self.makeQueue()

        for (index, kind) in Entry.Kind.allCases.enumerated() {
            let isTransfer = kind == .transfer
            let accepted = try Self.accepts(queue) { db in
                try db.execute(
                    sql: Self.insertEntry,
                    arguments: [
                        Self.id(index + 10),
                        kind.rawValue,
                        isTransfer ? nil : Self.categoryID,
                        isTransfer ? Self.toWalletID : nil
                    ]
                )
            }

            #expect(accepted, Self.hint)
        }

        let unknown = try Self.accepts(queue) { db in
            try db.execute(
                sql: Self.insertEntry,
                arguments: [Self.id(99), "unknown", Self.categoryID, nil]
            )
        }

        #expect(!unknown)
    }
}

extension LatestSchemaTests {
    static let iconID = id(1)
    static let walletID = id(2)
    static let toWalletID = id(3)
    static let categoryID = id(4)

    static func id(_ number: Int) -> String {
        "00000000-0000-4000-8000-\(String(format: "%012d", number))"
    }

    static func makeQueue() throws -> DatabaseQueue {
        let queue = try DatabaseQueue()

        try AppDatabase.migrator.migrate(queue)

        try queue.write { db in
            try db.execute(sql: insertIcon, arguments: [iconID])
            try db.execute(sql: insertWallet, arguments: [walletID, "cash"])
            try db.execute(sql: insertWallet, arguments: [toWalletID, "bank"])
            try db.execute(sql: insertCategory, arguments: [categoryID, "expense"])
        }

        return queue
    }

    static func accepts(
        _ queue: DatabaseQueue,
        _ write: (Database) throws -> Void
    ) throws -> Bool {
        do {
            try queue.write(write)

            return true
        } catch let error as DatabaseError
            where error.extendedResultCode == .SQLITE_CONSTRAINT_CHECK {
            return false
        }
    }
}

private extension LatestSchemaTests {
    static let timestamps = "'2026-10-12T00:00:00Z', '2026-10-12T00:00:00Z'"

    static let insertIcon = """
    INSERT INTO icon (id, emoji, text, color, created_at, updated_at)
    VALUES (?, '🎯', NULL, '#000000', \(timestamps))
    """

    static let insertWallet = """
    INSERT INTO wallet (id, name, kind, icon_id, initial_balance, sort_order, created_at, updated_at)
    VALUES (?, '財布', ?, '\(iconID)', 0, 0, \(timestamps))
    """

    static let insertCategory = """
    INSERT INTO category (id, kind, name, icon_id, sort_order, created_at, updated_at)
    VALUES (?, ?, '食費', '\(iconID)', 0, \(timestamps))
    """

    static let insertRecurring = """
    INSERT INTO recurring (id, type, amount, category_id, wallet_id, frequency, month, day, start_date, created_at, updated_at)
    VALUES (?, 'expense', 1, '\(categoryID)', '\(walletID)', ?, ?, 1, '2026-10-12', \(timestamps))
    """

    static let insertEntry = """
    INSERT INTO entry (id, type, amount, category_id, wallet_id, to_wallet_id, date, created_at, updated_at)
    VALUES (?, ?, 1, ?, '\(walletID)', ?, '2026-10-12', \(timestamps))
    """
}
