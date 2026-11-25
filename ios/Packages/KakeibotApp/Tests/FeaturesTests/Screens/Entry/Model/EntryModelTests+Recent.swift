import Core
import FeatureModels
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
        let model = EntryModel(parts: .system(setup.database), date: setup.date)
        await model.load()
        await model.reloadCategories()

        let amounts = model.output.recentEntries.map(\.amount)

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
        let model = EntryModel(parts: .system(setup.database), date: setup.date)
        await model.load()
        await model.reloadCategories()

        #expect(model.output.recentEntries.map(\.amount) == [220])
    }

    @Test
    func listsNoRecentEntriesForTransfers() async throws {
        let setup = try await Setup()
        _ = try await setup.saveEntry(amount: 980)
        let model = EntryModel(
            parts: .system(setup.database),
            date: setup.date,
            type: .transfer
        )
        await model.load()
        await model.reloadCategories()

        #expect(model.output.recentEntries.isEmpty)
    }

    @Test
    func appliesRecentEntry() async throws {
        let setup = try await Setup()
        let saved = try await setup.saveEntry(amount: 980)
        let model = EntryModel(parts: .system(setup.database), date: setup.date)
        await model.load()

        model.applyRecent(saved)

        #expect(model.output.amount == 980)
        #expect(model.state.category.id == saved.categoryId)
        #expect(model.state.payment.walletId == saved.walletId)
    }

    @Test
    func dropsRecentTagOutsideOfferedCategories() async throws {
        let setup = try await Setup()
        let options = try await setup.database.entryOptions()
        let category = options.expenseCategories[1]
        let shared = options.wallets[1]
        let drafts = [EntryTagDraft(name: "買い置き")]
        let tags = try await setup.database.saveTags(drafts, for: category.id, at: Date())
        let tag = try #require(tags.first)
        try await setup.database.startSharing(shared.id)

        let draft = EntryDraft(
            type: .expense,
            amount: 980,
            date: setup.date,
            categoryId: category.id,
            tagId: tag.id,
            walletId: shared.id
        )

        let fitted = try await setup.database.saveEntry(draft, at: Date())
        try await setup.database.setCategory(of: fitted.id, to: category.id, tagId: tag.id)
        let saved = try #require(await setup.database.entry(fitted.id))
        let model = EntryModel(parts: .system(setup.database), date: setup.date)
        await model.load()

        model.applyRecent(saved)

        #expect(fitted.tagId != tag.id)
        #expect(saved.tagId == tag.id)
        #expect(model.state.payment.walletId == shared.id)
        #expect(model.output.selectedCategory?.walletId == shared.id)
        #expect(model.state.category.tagId == nil)
        #expect(model.output.amount == 980)
    }

    @Test
    func leavesEditedEntryOutOfRecentEntries() async throws {
        let setup = try await Setup()
        _ = try await setup.saveEntry(amount: 980)
        let edited = try await setup.saveEntry(amount: 220)
        let model = EntryModel(
            parts: .system(setup.database),
            editing: edited.id,
            date: setup.date
        )

        await model.load()

        #expect(model.output.recentEntries.map(\.amount) == [980])
    }
}
