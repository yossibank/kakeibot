import Core
import Features
import Foundation
import Store
import Testing

@MainActor
struct TemplateUseTests {
    @Test
    func appliesTemplateToEntry() async throws {
        let setup = try await Setup()
        let lunch = try await setup.saveTemplate(name: "ランチ", amount: 980)
        let model = EntryModel(database: setup.database, date: setup.date)
        await model.load()

        model.apply(lunch)

        #expect(model.amount == 980)
        #expect(model.memo == "社食")
        #expect(model.categoryId == lunch.categoryId)
        #expect(model.isApplied(lunch))
    }

    @Test
    func startsFromTemplateWithoutChanges() async throws {
        let setup = try await Setup()
        let pass = try await setup.saveTemplate(name: "定期", amount: nil)

        let model = EntryModel(
            database: setup.database,
            date: setup.date,
            template: pass
        )
        await model.load()

        #expect(model.amount == 0)
        #expect(model.memo == "社食")
        #expect(!model.isChanged)
        #expect(model.templates.map(\.name) == ["定期"])
    }

    @Test
    func prefillsNewTemplateFromInput() async throws {
        let setup = try await Setup()
        let model = EntryModel(database: setup.database, date: setup.date)
        await model.load()
        model.press(.digit(4))
        model.press(.digit(5))
        model.press(.digit(0))
        model.memo = "カフェ"

        let editor = model.newTemplateModel()

        #expect(editor.amount == 450)
        #expect(editor.memo == "カフェ")
        #expect(editor.categoryId == model.categoryId)
        #expect(editor.name.isEmpty)
    }

    @Test
    func describesAndReordersTemplates() async throws {
        let setup = try await Setup()
        try await setup.saveTemplate(name: "ランチ", amount: 980)
        try await setup.saveTemplate(name: "定期", amount: nil)
        let model = TemplateListModel(database: setup.database)
        await model.load()
        let first = try #require(model.templates.first)
        let detail = model.detail(for: first)
        let amounts = model.templates.map { model.amountText(for: $0) }

        await model.move(from: [0], to: 2)
        let stored = try await setup.database.templates()

        #expect(detail == "支出・日用品・財布・社食")
        #expect(amounts == ["¥980", "毎回入れる"])
        #expect(stored.map(\.name) == ["定期", "ランチ"])
    }

    @Test
    func recordsFromHomeAndUndoes() async throws {
        let setup = try await Setup()
        let lunch = try await setup.saveTemplate(name: "ランチ", amount: 980)
        let home = HomeModel(database: setup.database, today: setup.date)

        await home.record(lunch)
        let recorded = home.recorded
        let afterRecord = try await setup.database.entryList()

        await home.undoRecorded()
        let afterUndo = try await setup.database.entryList()

        #expect(recorded?.message == "ランチ ¥980 を記録した")
        #expect(afterRecord.days.first?.entries.first?.amount == 980)
        #expect(afterRecord.days.first?.date == setup.date)
        #expect(afterUndo.days.isEmpty)
        #expect(home.recorded == nil)
    }
}

extension TemplateUseTests {
    struct Setup {
        let database: AppDatabase
        let date: LocalDate
    }
}

extension TemplateUseTests.Setup {
    init() async throws {
        let database = try AppDatabase.inMemory()
        try database.insertDefaultsIfEmpty(at: Date())
        let date = try #require(LocalDate("2026-10-15"))
        self.init(database: database, date: date)
    }

    @discardableResult
    func saveTemplate(
        name: String,
        amount: Int?
    ) async throws -> EntryTemplate {
        let options = try await database.entryOptions()

        let draft = EntryTemplateDraft(
            name: name,
            type: .expense,
            amount: amount,
            categoryId: options.expenseCategories[1].id,
            walletId: options.wallets[0].id,
            memo: "社食"
        )

        return try await database.saveTemplate(draft, at: Date())
    }
}
