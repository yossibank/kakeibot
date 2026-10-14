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
        let model = EntryModel(
            database: setup.database,
            editing: entry.id,
            date: setup.date
        )
        await model.load()

        model.press(.delete)
        let saved = await model.save()
        let stored = try await setup.database.entry(entry.id)

        #expect(saved)
        #expect(stored?.amount == 98)
        #expect(stored?.createdAt == entry.createdAt)
    }

    @Test
    func describesExpressionAndTax() async throws {
        let model = try await Self.newModel()

        for key: AmountCalculator.Key in [
            .digit(1),
            .digit(2),
            .doubleZero,
            .operation(.add),
            .digit(8)
        ] {
            model.press(key)
        }

        let expression = model.expressionText
        model.press(.equals)
        let settled = model.expressionText
        model.press(.tax(.standard))

        #expect(expression == "1,200 ＋ 8")
        #expect(settled == nil)
        #expect(model.expressionText == "1,208 の税込み 10%")
        #expect(model.amount == 1328)
    }

    @Test
    func groupsWalletsByKind() async throws {
        let model = try await Self.newModel()

        let sections = model.walletSections

        #expect(sections.map(\.kind) == [.cash, .bank])
        #expect(sections.map { $0.wallets.map(\.name) } == [["財布"], ["銀行"]])
    }

    @Test
    func splitsCategoriesAndAddIntoPages() async throws {
        let model = try await Self.newModel()

        let expensePages = model.categoryPages
        model.select(.income)
        let incomePages = model.categoryPages

        #expect(expensePages.map(\.count) == [12, 1])
        #expect(expensePages.last == [.add])
        #expect(incomePages.map(\.count) == [4])
        #expect(incomePages[0].last == .add)
    }

    @Test
    func selectsAddedCategory() async throws {
        let model = try await Self.newModel()
        model.select(.income)
        let editor = model.newCategoryModel()
        editor.name = "配当"
        editor.glyph = .invest

        let saved = try #require(await editor.save())
        await model.addCategory(saved)

        #expect(editor.kind == .income)
        #expect(model.categoryId == saved.id)
        #expect(model.categories.last?.name == "配当")
    }

    @Test
    func namesSaveButtonByState() async throws {
        let model = try await Self.newModel()

        let empty = model.saveTitle
        model.press(.digit(9))
        model.press(.digit(8))
        model.press(.digit(0))

        #expect(empty == "金額を入れてください")
        #expect(model.saveTitle == "¥980 を記録する")
    }

    @Test(arguments: [
        ("2026-10-12", "今日 10/12（月）"),
        ("2026-10-11", "昨日 10/11（日）"),
        ("2026-10-05", "10/5（月）"),
        ("2025-12-31", "2025/12/31（水）")
    ])
    func describesDate(text: String, expected: String) throws {
        let today = try #require(LocalDate("2026-10-12"))
        let date = try #require(LocalDate(text))

        let description = EntryModel.dateText(for: date, today: today)

        #expect(description == expected)
    }

    @Test
    func deletesExistingEntry() async throws {
        let setup = try await Setup()
        let entry = try await setup.saveEntry(amount: 980)
        let model = EntryModel(
            database: setup.database,
            editing: entry.id,
            date: setup.date
        )
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
