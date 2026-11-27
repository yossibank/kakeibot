import Core
import Foundation
import GRDB
@testable import Store
import Testing

struct RecordColumnTests {
    private static let hint = Comment(
        rawValue: "Core の型のプロパティの名前を変えたら、CodingKeys の rawValue に元のプロパティの名前（camelCase）を書く"
    )

    private static let unrecordedTables: Set = [
        "sync_change",
        "sync_record",
        "sync_share",
        "sync_state",
        "sync_waiting"
    ]

    @Test(arguments: Self.rows)
    func encodesEveryColumnOfTable(_ row: SampleRow) throws {
        let database = try AppDatabase.inMemory()

        let columns = try database.writer.read { db in
            try Set(db.columns(in: row.table).map(\.name))
        }

        let encoded = try row.encodedColumns()

        #expect(encoded.subtracting(columns).sorted() == [], Self.hint)
        #expect(columns.subtracting(encoded).sorted() == [], Self.hint)
    }

    @Test(arguments: Self.rows)
    func decodesWhatItEncodes(_ row: SampleRow) throws {
        #expect(try row.roundTrips(), Self.hint)
    }

    @Test
    func coversEveryTable() throws {
        let database = try AppDatabase.inMemory()

        let tables = try database.writer.read { db in
            try Set(String.fetchAll(db, sql: Self.tableQuery))
        }

        let sampled = Set(Self.rows.map(\.table))

        #expect(sampled == tables.subtracting(Self.unrecordedTables), "表を足したら、ここに行の見本を足す")
    }
}

extension RecordColumnTests {
    struct SampleRow: Sendable, CustomTestStringConvertible {
        let table: String
        let encodedColumns: @Sendable () throws -> Set<String>
        let roundTrips: @Sendable () throws -> Bool

        var testDescription: String {
            table
        }

        init<Record: StoreRecord & Equatable & Sendable>(_ record: Record) {
            self.table = Record.databaseTableName
            self.encodedColumns = { try Set(record.databaseDictionary.keys) }
            self.roundTrips = { try Record(row: Row(record.databaseDictionary)) == record }
        }
    }
}

private extension RecordColumnTests {
    static let tableQuery = """
    SELECT name FROM sqlite_master
    WHERE type = 'table' AND name NOT LIKE 'sqlite_%' AND name NOT LIKE 'grdb_%'
    """

    static let now = Date(timeIntervalSince1970: 1_791_000_000)
    static let day = LocalDate("2026-02-27")!
    static let month = YearMonth("2026-01")!

    static let rows: [SampleRow] = [
        SampleRow(
            Icon(
                emoji: "🍙",
                text: "ご",
                glyph: .food,
                color: "#FF8800",
                createdAt: now,
                updatedAt: now
            )
        ),
        SampleRow(
            ShelfIcon(
                iconId: Icon.ID(),
                sortOrder: 1,
                archivedAt: now,
                createdAt: now,
                updatedAt: now
            )
        ),
        SampleRow(
            Wallet(
                name: "奨学金",
                kind: .loan,
                iconId: Icon.ID(),
                initialBalance: -240_000,
                loanAmount: 300_000,
                sortOrder: 2,
                archivedAt: now,
                createdAt: now,
                updatedAt: now
            )
        ),
        SampleRow(
            Valuation(
                walletId: Wallet.ID(),
                date: day,
                amount: 1000,
                createdAt: now,
                updatedAt: now
            )
        ),
        SampleRow(
            Adjustment(
                walletId: Wallet.ID(),
                date: day,
                amount: -300,
                createdAt: now,
                updatedAt: now
            )
        ),
        SampleRow(
            EntryCategory(
                kind: .expense,
                name: "食費",
                iconId: Icon.ID(),
                sortOrder: 0,
                archivedAt: now,
                walletId: Wallet.ID(),
                createdAt: now,
                updatedAt: now
            )
        ),
        SampleRow(
            EntryTag(
                categoryId: EntryCategory.ID(),
                name: "外食",
                sortOrder: 0,
                archivedAt: now,
                createdAt: now,
                updatedAt: now
            )
        ),
        SampleRow(
            EntryTemplate(
                name: "昼ごはん",
                type: .expense,
                amount: 800,
                categoryId: EntryCategory.ID(),
                tagId: EntryTag.ID(),
                walletId: Wallet.ID(),
                memo: "社食",
                billShift: 1,
                sortOrder: 0,
                archivedAt: now,
                createdAt: now,
                updatedAt: now
            )
        ),
        SampleRow(
            Recurring(
                type: .transfer,
                amount: 980,
                categoryId: EntryCategory.ID(),
                walletId: Wallet.ID(),
                toWalletId: Wallet.ID(),
                memo: "カード",
                frequency: .yearly,
                month: 3,
                day: 27,
                holidayShift: .next,
                closingDay: 15,
                fee: 110,
                finalAmount: 500,
                billShift: 1,
                startDate: day,
                endDate: day,
                remindDaysBefore: 2,
                generatedUntil: day,
                sortOrder: 1,
                archivedAt: now,
                createdAt: now,
                updatedAt: now
            )
        ),
        SampleRow(
            Entry(
                type: .expense,
                amount: 980,
                date: day,
                categoryId: EntryCategory.ID(),
                tagId: EntryTag.ID(),
                templateId: EntryTemplate.ID(),
                walletId: Wallet.ID(),
                toWalletId: Wallet.ID(),
                memo: "動画",
                recurringId: Recurring.ID(),
                recurringDate: day,
                billMonth: month,
                transferId: Entry.ID(),
                taxIncluded: true,
                createdAt: now,
                updatedAt: now
            )
        ),
        SampleRow(
            EntryItem(
                entryId: Entry.ID(),
                name: "おにぎり",
                quantity: 2,
                amount: 300,
                taxRate: .reduced,
                sortOrder: 0,
                createdAt: now,
                updatedAt: now
            )
        ),
        SampleRow(
            ItemName(store: "コンビニ", raw: "ｵﾆｷﾞﾘ", name: "おにぎり", createdAt: now, updatedAt: now)
        ),
        SampleRow(
            Budget(categoryId: EntryCategory.ID(), fromMonth: month, amount: 30000)
        ),
        SampleRow(
            RewardRule(
                name: "自炊した日",
                amount: 300,
                iconId: Icon.ID(),
                isActive: true,
                sortOrder: 0,
                createdAt: now,
                updatedAt: now
            )
        ),
        SampleRow(
            RewardLog(ruleId: RewardRule.ID(), date: day, amount: 300, createdAt: now)
        ),
        SampleRow(
            RewardGoal(
                name: "新しい靴",
                targetAmount: 8000,
                purchasedAt: now,
                entryId: Entry.ID(),
                createdAt: now,
                updatedAt: now
            )
        ),
        SampleRow(
            CalendarStamp(date: day, iconId: Icon.ID(), createdAt: now)
        ),
        SampleRow(
            NoSpendDay(date: day, createdAt: now)
        ),
        SampleRow(
            Theme(
                name: "標準",
                background: "#FFFFFF",
                surface: "#F5F5F5",
                textPrimary: "#111111",
                textSecondary: "#666666",
                accent: "#FF8800",
                expense: "#D33F49",
                income: "#2E8B57",
                cornerRadius: 12,
                fontId: "system",
                isBuiltin: true,
                createdAt: now,
                updatedAt: now
            )
        ),
        SampleRow(
            Setting(key: .monthStartDay, value: "25")
        ),
        SampleRow(
            ReviewComment(period: "2026-01", body: "よくできました", basis: "{}", createdAt: now)
        ),
        SampleRow(
            ReviewGoal(
                period: "2026-01",
                kind: .count,
                categoryId: EntryCategory.ID(),
                memo: "外食を減らす",
                baseline: 10,
                target: 6,
                saving: 3000,
                result: 5,
                saved: 3500,
                createdAt: now,
                checkedAt: now
            )
        )
    ]
}
