import Core
import Features
import Foundation
import Store
import Testing

@MainActor
struct RecordsModelTests {
    @Test
    func showsOnlyDaysInMonth() async throws {
        let setup = try await Setup()
        try await setup.save(.expense, amount: 980, on: "2026-10-12")
        try await setup.save(.income, amount: 250_000, on: "2026-10-10")
        try await setup.save(.expense, amount: 3980, on: "2026-10-10")
        try await setup.save(.expense, amount: 500, on: "2026-09-30")
        let model = RecordsModel(database: setup.database, month: setup.month)

        await model.load()
        let dates = model.days.map(\.date.description)

        #expect(dates == ["2026-10-12", "2026-10-10"])
        #expect(model.expenseTotal == 4960)
        #expect(model.incomeTotal == 250_000)

        model.move(months: -1)

        #expect(model.month.description == "2026-09")
        #expect(model.days.map(\.date.description) == ["2026-09-30"])
        #expect(model.expenseTotal == 500)
    }

    @Test
    func describesRowsWithMemoAndWallet() async throws {
        let setup = try await Setup()
        try await setup.save(
            .expense,
            amount: 980,
            on: "2026-10-12",
            memo: "ランチ"
        )
        try await setup.save(.expense, amount: 220, on: "2026-10-12", memo: "")
        let model = RecordsModel(database: setup.database, month: setup.month)

        await model.load()
        let day = try #require(model.days.first)
        let rows = model.rows(for: day)

        #expect(rows.map(\.detail) == ["財布", "ランチ・財布"])
        #expect(rows.map(\.type) == [.expense, .expense])
    }

    @Test
    func deletesRowAndUndoes() async throws {
        let setup = try await Setup()
        try await setup.save(.expense, amount: 980, on: "2026-10-12")
        let model = RecordsModel(database: setup.database, month: setup.month)
        let notice = EntryNoticeModel(database: setup.database)
        await model.load()
        let day = try #require(model.days.first)
        let row = try #require(model.rows(for: day).first)

        let change = try #require(await model.delete(row.id))
        let deleted = try setup.database.snapshot().entries
        notice.show(change)
        await notice.undo()
        let restored = try setup.database.snapshot().entries

        #expect(change.message == "食費 ¥980 を消した")
        #expect(deleted.isEmpty)
        #expect(restored.map(\.id) == [row.id])
    }
}

extension RecordsModelTests {
    struct Setup {
        let database: AppDatabase
        let month: YearMonth
    }
}

extension RecordsModelTests.Setup {
    init() async throws {
        let database = try AppDatabase.inMemory()
        try database.insertDefaultsIfEmpty(at: Date())
        let month = try #require(YearMonth("2026-10"))
        self.init(database: database, month: month)
    }

    func save(
        _ type: Entry.Kind,
        amount: Int,
        on text: String,
        memo: String = ""
    ) async throws {
        let options = try await database.entryOptions()
        let categories = type == .income
            ? options.incomeCategories
            : options.expenseCategories
        let date = try #require(LocalDate(text))
        let days = try await database.entryList().days
        let count = days.reduce(0) { $0 + $1.entries.count }
        let offset = TimeInterval(count)
        let createdAt = Date(timeIntervalSince1970: 1_791_000_000 + offset)

        let draft = EntryDraft(
            type: type,
            amount: amount,
            date: date,
            categoryId: categories.first?.id,
            walletId: options.wallets[0].id,
            memo: memo
        )

        try await database.saveEntry(draft, at: createdAt)
    }
}
