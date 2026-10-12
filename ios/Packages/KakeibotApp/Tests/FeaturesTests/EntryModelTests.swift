import Core
import Features
import Foundation
import Store
import Testing

@MainActor
struct EntryModelTests {
    @Test
    func buildsAmountFromKeys() async throws {
        let model = try await Self.newModel()

        model.press(.digit(1))
        model.press(.digit(2))
        model.press(.doubleZero)

        #expect(model.amount == 1200)

        model.press(.delete)

        #expect(model.amount == 120)
    }

    @Test
    func capsAmountAtNineDigits() async throws {
        let model = try await Self.newModel()

        for _ in 0..<10 {
            model.press(.digit(9))
        }

        #expect(model.amount == 999_999_999)
    }

    @Test
    func picksFirstCategoryOfSelectedType() async throws {
        let model = try await Self.newModel()

        model.select(.income)

        #expect(model.categoryId == model.options?.incomeCategories.first?.id)
    }

    @Test
    func savesNewEntry() async throws {
        let setup = try await Setup()
        let model = EntryModel(database: setup.database, date: setup.date)
        await model.load()
        model.press(.digit(5))
        model.press(.doubleZero)
        model.memo = "ランチ"

        let saved = await model.save()
        let entries = try setup.database.snapshot().entries

        #expect(saved)
        #expect(entries.map(\.amount) == [500])
        #expect(entries.map(\.memo) == ["ランチ"])
    }

    @Test
    func refusesZeroAmount() async throws {
        let model = try await Self.newModel()

        let saved = await model.save()

        #expect(model.canSave == false)
        #expect(saved == false)
        #expect(model.errorMessage == "金額を入れてください")
    }

    @Test
    func editsExistingEntry() async throws {
        let setup = try await Setup()
        let entry = try await setup.saveEntry(amount: 980)
        let model = EntryModel(database: setup.database, editing: entry.id, date: setup.date)
        await model.load()

        model.press(.delete)
        let saved = await model.save()
        let stored = try await setup.database.entry(entry.id)

        #expect(saved)
        #expect(stored?.amount == 98)
        #expect(stored?.createdAt == entry.createdAt)
    }

    @Test
    func deletesExistingEntry() async throws {
        let setup = try await Setup()
        let entry = try await setup.saveEntry(amount: 980)
        let model = EntryModel(database: setup.database, editing: entry.id, date: setup.date)
        await model.load()

        let deleted = await model.delete()
        let stored = try await setup.database.entry(entry.id)

        #expect(deleted)
        #expect(stored == nil)
    }
}

extension EntryModelTests {
    struct Setup {
        let database: AppDatabase
        let date: LocalDate
    }
}

extension EntryModelTests.Setup {
    init() async throws {
        let database = try AppDatabase.inMemory()
        try database.insertDefaultsIfEmpty(at: Date())
        let date = try #require(LocalDate("2026-10-12"))
        self.init(database: database, date: date)
    }

    func saveEntry(amount: Int) async throws -> Entry {
        let options = try await database.entryOptions()
        let categoryId = options.expenseCategories.first?.id
        let walletId = try #require(options.wallets.first?.id)

        let draft = EntryDraft(
            type: .expense,
            amount: amount,
            date: date,
            categoryId: categoryId,
            walletId: walletId
        )

        let now = Date(timeIntervalSince1970: 1_791_000_000)
        return try await database.saveEntry(draft, at: now)
    }
}

private extension EntryModelTests {
    static func newModel() async throws -> EntryModel {
        let setup = try await Setup()
        let model = EntryModel(database: setup.database, date: setup.date)
        await model.load()
        return model
    }
}
