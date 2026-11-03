import Core
import Features
import Foundation
import Store
import Testing

@MainActor
struct TemplateListModelTests {
    @Test
    func hidesAndShowsTemplate() async throws {
        let database = try AppDatabase.inMemory()
        try database.insertDefaultsIfEmpty(at: Date())
        let options = try await database.entryOptions()

        let draft = EntryTemplateDraft(
            name: "ランチ",
            type: .expense,
            amount: 980,
            categoryId: options.expenseCategories[0].id,
            walletId: options.wallets[0].id
        )

        let saved = try await database.saveTemplate(draft, at: Date())
        let model = TemplateListModel(database: database)
        await model.load()

        await model.hide(saved.id)
        let shown = model.shown.map(\.id)
        let hidden = model.hidden.map(\.id)
        let homeTemplates = try await database.templates()

        await model.show(saved.id)

        #expect(shown.isEmpty)
        #expect(hidden == [saved.id])
        #expect(homeTemplates.isEmpty)
        #expect(model.hidden.isEmpty)
        #expect(model.shown.map(\.id) == [saved.id])
    }

    @Test
    func describesAndReordersTemplates() async throws {
        let setup = try await TemplateSetup()
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
}
