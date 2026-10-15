import Core
import Features
import Foundation
import Store
import Testing

@MainActor
struct AssetsModelTests {
    @Test
    func sumsBalancesByWalletAndMonth() async throws {
        let setup = try await Setup()

        try await setup.save(
            .income,
            250_000,
            on: "2026-09-25",
            from: setup.bank
        )

        try await setup.save(.expense, 980, on: "2026-10-01", from: setup.cash)

        try await setup.save(
            .transfer,
            10000,
            on: "2026-10-02",
            from: setup.bank,
            to: setup.cash
        )

        let model = AssetsModel(database: setup.database, today: setup.today)
        await model.load()
        let balances = model.rows.map(\.balance)
        let totals = model.monthTotals.map(\.total)

        #expect(model.total == 249_020)
        #expect(balances == [9020, 240_000])
        #expect(model.changeFromLastMonth == -980)
        #expect(totals == [0, 0, 0, 0, 250_000, 249_020])
        #expect(model.monthTotals.last?.month == setup.today.yearMonth)
    }

    @Test
    func showsAndUndoesTransfer() async throws {
        let setup = try await Setup()

        let entry = try await setup.save(
            .transfer,
            3000,
            on: "2026-10-10",
            from: setup.bank,
            to: setup.cash
        )

        let model = AssetsModel(database: setup.database, today: setup.today)
        await model.load()

        model.showTransfer(entry)
        let message = model.transferred?.message
        await model.undoTransfer()
        let entries = try setup.database.snapshot().entries

        #expect(message == "銀行 → 財布 ¥3,000 を振り替えた")
        #expect(model.transferred == nil)
        #expect(entries.isEmpty)
    }
}

extension AssetsModelTests {
    struct Setup {
        let database: AppDatabase
        let today: LocalDate
        let cash: Wallet.ID
        let bank: Wallet.ID
        let food: EntryCategory.ID
        let salary: EntryCategory.ID
    }
}

extension AssetsModelTests.Setup {
    init() async throws {
        let database = try AppDatabase.inMemory()
        try database.insertDefaultsIfEmpty(at: Date())
        let options = try await database.entryOptions()
        let today = try #require(LocalDate("2026-10-15"))

        self.init(
            database: database,
            today: today,
            cash: options.wallets[0].id,
            bank: options.wallets[1].id,
            food: options.expenseCategories[0].id,
            salary: options.incomeCategories[0].id
        )
    }

    @discardableResult
    func save(
        _ type: Entry.Kind,
        _ amount: Int,
        on text: String,
        from wallet: Wallet.ID,
        to destination: Wallet.ID? = nil
    ) async throws -> Entry {
        let date = try #require(LocalDate(text))

        let category: EntryCategory.ID? = switch type {
        case .expense: food
        case .income: salary
        case .transfer: nil
        }

        let draft = EntryDraft(
            type: type,
            amount: amount,
            date: date,
            categoryId: category,
            walletId: wallet,
            toWalletId: destination
        )

        return try await database.saveEntry(draft, at: Date())
    }
}
