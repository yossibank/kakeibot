import Core
@testable import FeatureModels
import Foundation
import Store
import Testing

extension EntryModelTests {
    @Test
    func reportsReadyAfterFirstLoadOnly() async throws {
        let setup = try await Setup()
        let model = EntryModel(parts: .system(setup.database), date: setup.date)

        await model.start()
        let first = model.state.results.outcome
        await model.start()

        #expect(first.value == .ready(isFirst: true))
        #expect(model.state.results.outcome.value == .ready(isFirst: false))
        #expect(model.state.results.outcome != first)
        #expect(model.output.isLoaded)
    }

    @Test
    func dropsUndoNoticesWhenStartingAgain() async throws {
        let setup = try await Setup()
        let model = EntryModel(parts: .system(setup.database), date: setup.date)
        await model.start()
        let category = try #require(model.output.categories.first)
        model.state.results.deletion = Deletion(merging: [])
        model.state.results.hiddenCategory = .init(id: category.id, wasSelected: false)

        await model.start()

        #expect(model.state.results.deletion == nil)
        #expect(model.state.results.hiddenCategory == nil)
    }

    @Test
    func placesSavedChangeAndBeginsClosing() async throws {
        let model = try await Self.newModel()
        model.state.press(.digit(5))

        let change = try #require(await model.save())

        #expect(model.state.results.outcome.value == .closed(change))
        #expect(model.state.progress.isClosing)
    }

    @Test
    func placesNoOutcomeWhenSavingFails() async throws {
        let setup = try await Setup()
        let model = EntryModel(parts: .system(setup.database), date: setup.date)
        await model.load()
        model.state.press(.digit(5))
        try await setup.database.failWrites(to: "entry")

        let change = await model.save()

        #expect(change == nil)
        #expect(model.state.results.outcome.value == nil)
        #expect(!model.state.progress.isClosing)
    }

    @Test
    func continuesWithNextEntryAfterSaving() async throws {
        let model = try await Self.newModel()
        model.state.press(.digit(5))

        let change = try #require(await model.saveAndContinue())
        let amount = model.output.amount
        model.state.press(.digit(7))
        let next = await model.saveAndContinue()

        #expect(amount == 0)
        #expect(!model.state.progress.isClosing)
        #expect(next != nil)
        #expect(next?.entry.id != change.entry.id)
        #expect(model.state.results.outcome.value == next.map(EntryModel.Outcome.continued))
    }

    @Test
    func placesDeletedChangeAndBeginsClosing() async throws {
        let setup = try await Setup()
        let entry = try await setup.saveEntry(amount: 980)
        let model = EntryModel(
            parts: .system(setup.database),
            editing: entry.id,
            date: setup.date
        )
        await model.load()

        let change = try #require(await model.delete())

        #expect(change.kind == .deleted)
        #expect(model.state.results.outcome.value == .closed(change))
        #expect(model.state.progress.isClosing)
    }

    @Test
    func movesCategoryAfterRecordingAgain() async throws {
        let setup = try await Setup()
        let entry = try await setup.saveEntry(amount: 980)
        let model = EntryModel(
            parts: .system(setup.database),
            editing: entry.id,
            date: setup.date
        )
        await model.load()

        await model.recordAgain()

        #expect(model.state.results.outcome.value == .categoryMoved)
        #expect(!model.output.isEditing)
    }

    @Test
    func placesHiddenCategoryAndMovesBackOnUndo() async throws {
        let model = try await Self.newModel()
        let food = try #require(model.output.selectedCategory)

        let hidden = try #require(await model.hideCategory(food))
        let placed = model.state.results.hiddenCategory
        let hiding = model.state.results.outcome.value
        await model.showCategory(hidden)

        #expect(placed == hidden)
        #expect(hiding == nil)
        #expect(model.state.results.outcome.value == .categoryMoved)
    }

    @Test
    func clearsHiddenCategoryWhenHidingFails() async throws {
        let setup = try await Setup()
        let model = EntryModel(parts: .system(setup.database), date: setup.date)
        await model.load()
        let food = try #require(model.output.selectedCategory)
        let other = try #require(model.output.categories.last)
        _ = await model.hideCategory(other)
        try await setup.database.failWrites(to: "category")

        let hidden = await model.hideCategory(food)

        #expect(hidden == nil)
        #expect(model.state.results.hiddenCategory == nil)
    }

    @Test
    func reportsAddedCategory() async throws {
        let model = try await Self.newModel()
        let editor = model.newCategoryModel()
        editor.state.name = "おやつ"
        let saved = try #require(await editor.save())

        await model.addCategory(saved.id)

        #expect(model.state.category.id == saved.id)
        #expect(model.state.results.outcome.value == .categoryAdded)
    }

    @Test
    func choosesAddedWalletAfterSheet() async throws {
        let model = try await Self.newModel()
        let editor = model.newWalletModel()
        editor.state.name = "へそくり"
        let wallet = try #require(await editor.save())
        let added = EntryModel.AddedWallet(wallet: wallet, role: .source)

        await model.reloadAfterSheet(wallets: false, adding: added)
        let skipped = model.state.results.outcome.value
        let before = model.state.payment.walletId
        await model.reloadAfterSheet(wallets: true, adding: added)

        #expect(skipped == nil)
        #expect(before != wallet.id)
        #expect(model.state.payment.walletId == wallet.id)
        #expect(model.state.results.outcome.value == .walletChosen)
    }

    @Test
    func choosesDestinationByRole() async throws {
        let model = try await Self.newModel()
        model.select(.transfer)
        let source = model.state.payment.walletId
        let wallet = try #require(model.output.wallets.last { $0.id != source })

        model.choose(wallet.id, as: .destination)

        #expect(model.state.payment.toWalletId == wallet.id)
        #expect(model.state.payment.walletId == source)
    }
}
