import Core
@testable import FeatureModels
@testable import Features
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
        let model = TemplateListModel(parts: .system(database))
        await model.load()

        await model.hide(saved.id)
        let shown = model.output.shown.map(\.id)
        let hidden = model.output.hidden.map(\.id)
        let homeTemplates = try await database.templates()

        await model.show(saved.id)

        #expect(shown.isEmpty)
        #expect(hidden == [saved.id])
        #expect(homeTemplates.isEmpty)
        #expect(model.output.hidden.isEmpty)
        #expect(model.output.shown.map(\.id) == [saved.id])
    }

    @Test
    func describesAndReordersTemplates() async throws {
        let setup = try await TemplateSetup()
        try await setup.saveTemplate(name: "ランチ", amount: 980)
        try await setup.saveTemplate(name: "給料", amount: nil, type: .income)
        let pass = try await setup.saveTemplate(name: "定期", amount: nil)
        let model = TemplateListModel(parts: .system(setup.database))
        await model.load()
        let first = try #require(model.output.shown.first)
        let detail = model.output.detail(for: first)

        model.move(pass.id, to: 0)
        let moving = model.output.shown.map(\.name)
        await model.finishMoving()
        let stored = try await setup.database.templates()

        model.state.type = .income
        let income = model.output.shown.map(\.name)

        #expect(detail == "日用品・財布")
        #expect(moving == ["定期", "ランチ"])
        #expect(stored.map(\.name) == ["定期", "ランチ", "給料"])
        #expect(income == ["給料"])
        #expect(model.state.movingOrder == nil)
    }
}
