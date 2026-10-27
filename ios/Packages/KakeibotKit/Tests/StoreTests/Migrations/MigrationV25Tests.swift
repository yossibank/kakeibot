import GRDB
@testable import Store
import Testing

struct MigrationV25Tests {
    @Test
    func movesRecurringDateToScheduledDate() throws {
        let queue = try Self.migratedQueue()

        let dates = try queue.read { db in
            try Self.pairs(
                db,
                sql: "SELECT id, recurring_date FROM entry WHERE recurring_id IS NOT NULL"
            )
        }

        #expect(dates["next"] == "2027-02-27")
        #expect(dates["previous"] == "2027-05-01")
        #expect(dates["plain"] == "2026-03-25")
        #expect(dates["lost"] == "2027-08-14")
    }

    @Test
    func movesBillMonthOnlyWhenOneScheduledDateFits() throws {
        let queue = try Self.migratedQueue()

        let months = try queue.read { db in
            try Self.pairs(
                db,
                sql: "SELECT id, bill_month FROM entry WHERE bill_month IS NOT NULL"
            )
        }

        #expect(months["one"] == "2026-12")
        #expect(months["two"] == "2027-03")
    }
}

private extension MigrationV25Tests {
    static let stamp = "'2026-01-01T00:00:00Z', '2026-01-01T00:00:00Z'"
    static let bank = "'00000000-0000-4000-8000-00000000000a'"
    static let cardOne = "'00000000-0000-4000-8000-0000000000c1'"
    static let cardTwo = "'00000000-0000-4000-8000-0000000000c2'"

    static let nextID = "00000000-0000-4000-8000-000000000001"
    static let previousID = "00000000-0000-4000-8000-000000000002"
    static let plainID = "00000000-0000-4000-8000-000000000003"
    static let billOneID = "00000000-0000-4000-8000-000000000004"
    static let billTwoID = "00000000-0000-4000-8000-000000000005"

    static var seed: String {
        let parts = [
            base,
            recurring(nextID, day: 27, shift: "next"),
            recurring(previousID, day: 1, shift: "previous"),
            recurring(plainID, day: 25, shift: "none"),
            recurring(billOneID, to: cardOne, day: 31, shift: "next"),
            recurring(billTwoID, to: cardTwo, day: 27, shift: "next"),
            recorded("next", recurring: nextID, on: "2027-03-01"),
            recorded("previous", recurring: previousID, on: "2027-04-30"),
            recorded("plain", recurring: plainID, on: "2026-03-25"),
            recorded("lost", recurring: plainID, on: "2027-08-14"),
            billed("one", card: cardOne, month: "2027-01"),
            billed("two", card: cardTwo, month: "2027-03")
        ]

        return parts.joined(separator: "\n")
    }

    static var base: String {
        """
        INSERT INTO icon (id, emoji, color, created_at, updated_at)
        VALUES ('i', '💴', '#000000', \(stamp));
        INSERT INTO wallet (id, name, kind, icon_id, initial_balance, \
        sort_order, created_at, updated_at)
        VALUES (\(bank), '銀行', 'bank', 'i', 0, 0, \(stamp)), \
        (\(cardOne), 'カード1', 'card', 'i', 0, 1, \(stamp)), \
        (\(cardTwo), 'カード2', 'card', 'i', 0, 2, \(stamp));
        INSERT INTO category (id, kind, name, icon_id, sort_order, \
        created_at, updated_at)
        VALUES ('k', 'expense', '住まい', 'i', 0, \(stamp));
        """
    }

    static func migratedQueue() throws -> DatabaseQueue {
        let queue = try DatabaseQueue()
        let migrator = AppDatabase.migrator
        try migrator.migrate(queue, upTo: "v24")

        try queue.write { db in
            try db.execute(sql: seed)
        }

        try migrator.migrate(queue)

        return queue
    }

    static func pairs(
        _ db: Database,
        sql: String
    ) throws -> [String: String] {
        try Row.fetchAll(db, sql: sql).reduce(into: [:]) { result, row in
            result[row[0]] = row[1]
        }
    }

    static func recurring(
        _ id: String,
        to card: String? = nil,
        day: Int,
        shift: String
    ) -> String {
        let type = card == nil ? "expense" : "transfer"
        let category = card == nil ? "'k'" : "NULL"
        let closing = card == nil ? "NULL" : "31"

        return """
        INSERT INTO recurring (id, type, amount, category_id, wallet_id, \
        to_wallet_id, frequency, day, holiday_shift, closing_day, start_date, \
        created_at, updated_at)
        VALUES ('\(id)', '\(type)', 1000, \(category), \(bank), \
        \(card ?? "NULL"), 'monthly', \(day), '\(shift)', \(closing), \
        '2026-01-01', \(stamp));
        """
    }

    static func recorded(
        _ id: String,
        recurring: String,
        on date: String
    ) -> String {
        """
        INSERT INTO entry (id, type, amount, date, category_id, wallet_id, \
        recurring_id, recurring_date, created_at, updated_at)
        VALUES ('\(id)', 'expense', 1000, '\(date)', 'k', \(bank), \
        '\(recurring)', '\(date)', \(stamp));
        """
    }

    static func billed(
        _ id: String,
        card: String,
        month: String
    ) -> String {
        """
        INSERT INTO entry (id, type, amount, date, category_id, wallet_id, \
        bill_month, created_at, updated_at)
        VALUES ('\(id)', 'expense', 500, '2026-12-01', 'k', \(card), \
        '\(month)', \(stamp));
        """
    }
}
