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
}
