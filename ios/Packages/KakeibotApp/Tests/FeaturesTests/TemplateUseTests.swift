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
    func appliesTagAndDropsItWithOtherCategory() async throws {
        let setup = try await Setup()
        let tag = try await setup.saveTag("買い置き")
        let stock = try await setup.saveTemplate(
            name: "買い置き",
            amount: 1200,
            tagId: tag.id
        )
        let model = EntryModel(database: setup.database, date: setup.date)
        await model.load()

        model.apply(stock)
        let applied = model.tagId
        let tags = model.tags.map(\.name)
        let saved = await model.save()
        let entry = try await setup.database.entryList().days.first?.entries

        model.categoryId = model.categories.first?.id

        #expect(applied == tag.id)
        #expect(tags == ["買い置き"])
        #expect(saved)
        #expect(entry?.first?.tagId == tag.id)
        #expect(model.tagId == nil)
        #expect(!model.isApplied(stock))
    }

    @Test
    func highlightsOnlyTheAppliedTemplate() async throws {
        let setup = try await Setup()
        let pass = try await setup.saveTemplate(name: "定期", amount: nil)
        let bus = try await setup.saveTemplate(name: "バス", amount: nil)
        let model = EntryModel(database: setup.database, date: setup.date)
        await model.load()

        model.apply(bus)

        #expect(model.isApplied(bus))
        #expect(!model.isApplied(pass))
    }

    @Test
    func startsFromTemplateWithoutChanges() async throws {
        let setup = try await Setup()
        let pass = try await setup.saveTemplate(name: "定期", amount: nil)
        try await setup.saveTemplate(name: "給料", amount: nil, type: .income)

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
        try await setup.saveTemplate(name: "給料", amount: nil, type: .income)
        let pass = try await setup.saveTemplate(name: "定期", amount: nil)
        let model = TemplateListModel(database: setup.database)
        await model.load()
        let first = try #require(model.shown.first)
        let detail = model.detail(for: first)

        model.move(pass.id, to: 0)
        let moving = model.shown.map(\.name)
        await model.finishMoving()
        let stored = try await setup.database.templates()

        model.type = .income
        let income = model.shown.map(\.name)

        #expect(detail == "日用品・財布")
        #expect(moving == ["定期", "ランチ"])
        #expect(stored.map(\.name) == ["定期", "ランチ", "給料"])
        #expect(income == ["給料"])
        #expect(model.movingOrder == nil)
    }

    @Test
    func showsTemplatesOfSelectedTypeOnHome() async throws {
        let setup = try await Setup()
        try await setup.saveTemplate(name: "ランチ", amount: 980)
        try await setup.saveTemplate(name: "給料", amount: nil, type: .income)
        let home = HomeModel(database: setup.database, today: setup.date)

        let task = Task {
            await home.observeTemplates()
        }

        for _ in 0..<200 where home.templates.isEmpty {
            try await Task.sleep(for: .milliseconds(10))
        }

        let expense = home.templates.map(\.name)
        home.templateType = .income
        let income = home.templates.map(\.name)
        task.cancel()

        #expect(expense == ["ランチ"])
        #expect(income == ["給料"])
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

    func saveTag(_ name: String) async throws -> EntryTag {
        let list = try await database.categoryList()
        let options = try await database.entryOptions()
        let category = options.expenseCategories[1]
        let icon = try #require(list.icons[category.iconId])

        try await database.saveCategory(
            CategoryDraft(category, icon: icon),
            tags: [EntryTagDraft(name: name)],
            editing: category.id,
            at: Date()
        )

        let tags = try await database.categoryList().tags
        return try #require(tags.first)
    }

    @discardableResult
    func saveTemplate(
        name: String,
        amount: Int?,
        type: Entry.Kind = .expense,
        tagId: EntryTag.ID? = nil
    ) async throws -> EntryTemplate {
        let options = try await database.entryOptions()

        let categories = type == .income
            ? options.incomeCategories
            : options.expenseCategories

        let draft = EntryTemplateDraft(
            name: name,
            type: type,
            amount: amount,
            categoryId: categories[1].id,
            tagId: tagId,
            walletId: options.wallets[0].id,
            memo: "社食"
        )

        return try await database.saveTemplate(draft, at: Date())
    }
}
