import Core
import Features
import Foundation
import Store
import Testing

extension EntryModelTests {
    @Test
    func listsRecentEntriesWithoutRepeats() async throws {
        let setup = try await Setup()
        _ = try await setup.saveEntry(amount: 980)
        _ = try await setup.saveEntry(amount: 980)
        _ = try await setup.saveEntry(amount: 220)
        _ = try await setup.saveEntry(amount: 1540)
        _ = try await setup.saveEntry(amount: 300)
        let model = EntryModel(database: setup.database, date: setup.date)
        await model.load()
        await model.reloadCategories()

        let amounts = model.recentEntries.map(\.amount)

        #expect(amounts.count == EntryModel.recentEntryLimit)
        #expect(Set(amounts).count == amounts.count)
    }

    @Test
    func skipsRecentEntriesThatMatchTemplates() async throws {
        let setup = try await TemplateSetup()
        let template = try await setup.saveTemplate(name: "ランチ", amount: 980)

        let same = EntryDraft(
            type: .expense,
            amount: 980,
            date: setup.date,
            categoryId: template.categoryId,
            walletId: template.walletId,
            memo: "社食"
        )

        let other = EntryDraft(
            type: .expense,
            amount: 220,
            date: setup.date,
            categoryId: template.categoryId,
            walletId: template.walletId
        )

        _ = try await setup.database.saveEntry(same, at: Date())
        _ = try await setup.database.saveEntry(other, at: Date())
        let model = EntryModel(database: setup.database, date: setup.date)
        await model.load()
        await model.reloadCategories()

        #expect(model.recentEntries.map(\.amount) == [220])
    }

    @Test
    func listsNoRecentEntriesForTransfers() async throws {
        let setup = try await Setup()
        _ = try await setup.saveEntry(amount: 980)
        let model = EntryModel(database: setup.database, date: setup.date, type: .transfer)
        await model.load()
        await model.reloadCategories()

        #expect(model.recentEntries.isEmpty)
    }

    @Test
    func appliesRecentEntry() async throws {
        let setup = try await Setup()
        let saved = try await setup.saveEntry(amount: 980)
        let model = EntryModel(database: setup.database, date: setup.date)
        await model.load()

        model.applyRecent(saved)

        #expect(model.amount == 980)
        #expect(model.categoryId == saved.categoryId)
        #expect(model.walletId == saved.walletId)
    }
}
