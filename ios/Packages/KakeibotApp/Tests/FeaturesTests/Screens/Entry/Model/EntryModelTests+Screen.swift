import Core
@testable import FeatureModels
import Foundation
import Store
import Testing

extension EntryModelTests {
    @Test
    func showsDeckWithItsDirectionAndKeypadTarget() async throws {
        let model = try await Self.newModel()
        model.select(.transfer)
        model.state.resetDeck()

        model.state.show(.fee)
        let fee = model.state.screen
        let feeTarget = model.state.keypad.target
        model.state.show(.transfer)

        #expect(fee.deck == .fee)
        #expect(fee.isForward)
        #expect(feeTarget == .fee)
        #expect(model.state.screen.deck == .transfer)
        #expect(!model.state.screen.isForward)
        #expect(model.state.keypad.target == .amount)
    }

    @Test
    func resetsDeckToFirstFieldOfType() async throws {
        let model = try await Self.newModel()
        model.state.show(.date)
        model.select(.transfer)
        model.state.enter(.fee)

        model.state.resetDeck()

        #expect(model.state.screen.deck == .transfer)
        #expect(model.state.keypad.target == .amount)
    }

    @Test
    func startsFromFirstFieldWhenTypeChanges() async throws {
        let model = try await Self.newModel()
        model.state.show(.date)

        model.select(.transfer)
        let transfer = model.state.screen.deck
        model.state.show(.amount)
        model.select(.income)

        #expect(transfer == .transfer)
        #expect(model.state.screen.deck == .category)
    }

    @Test
    func placesDeckWithoutChangingKeypadTarget() async throws {
        let model = try await Self.newModel()
        model.select(.transfer)

        model.state.place(.fee)

        #expect(model.state.screen.deck == .fee)
        #expect(model.state.keypad.target == .amount)
    }

    @Test
    func endsWalletEditingWhenWalletDeckOpensAgain() async throws {
        let model = try await Self.newModel()
        model.state.show(.wallet(.source))
        model.state.screen.wallets.isEditing = true

        model.state.show(.wallet(.source))
        let kept = model.state.screen.wallets.isEditing
        model.state.show(.amount)
        let left = model.state.screen.wallets.isEditing
        model.state.show(.wallet(.source))

        #expect(kept)
        #expect(left)
        #expect(!model.state.screen.wallets.isEditing)
    }

    @Test
    func showsPageOfSelectedCategory() async throws {
        let model = try await Self.newModel()
        var added: EntryCategory.ID?

        for index in 0..<EntryModel.categoriesPerPage {
            let editor = model.newCategoryModel()
            editor.state.fields.name = "追加\(index)"
            added = try #require(await editor.save()).id
        }

        try await model.addCategory(#require(added))
        model.showSelectedCategory()
        let page = model.state.screen.categoryPage
        model.state.setCategory(model.output.categories.first?.id)
        model.showSelectedCategory()

        #expect(model.output.categoryPages.count > 1)
        #expect(page == model.output.categoryPages.count - 1)
        #expect(model.state.screen.categoryPage == 0)
    }

    @Test
    func choosesAddedWalletAfterWalletSheetOnce() async throws {
        let model = try await Self.newModel()
        let editor = model.newWalletModel()
        editor.state.fields.name = "へそくり"
        let wallet = try #require(await editor.save())

        model.state.open(.newWallet(.source))
        let opened = model.state.screen.sheet
        model.state.noteAdded(wallet, as: .source)
        model.state.screen.sheet = nil
        await model.reloadAfterSheet()
        let chosen = model.state.results.outcome
        await model.reloadAfterSheet()

        #expect(opened == .newWallet(.source))
        #expect(model.state.payment.walletId == wallet.id)
        #expect(chosen.value == .walletChosen)
        #expect(model.state.results.outcome == chosen)
    }

    @Test
    func skipsWalletsAfterOtherSheets() async throws {
        let model = try await Self.newModel()
        let before = model.state.payment.walletId

        model.state.open(.newCategory)
        model.state.screen.sheet = nil
        await model.reloadAfterSheet()

        #expect(model.state.payment.walletId == before)
        #expect(model.state.results.outcome.value == nil)
    }

    @Test
    func holdsMenuMemoAndDiscardConfirmation() async throws {
        let model = try await Self.newModel()
        let category = try #require(model.output.categories.first)

        model.state.openMenu(for: category)
        model.state.editMemo(true)
        let menu = model.state.screen
        model.state.confirmDiscard()
        let discard = model.state.screen
        model.state.closeMenu()
        model.state.editMemo(false)

        #expect(menu.menuCategory == category)
        #expect(menu.isEditingMemo)
        #expect(discard.isConfirmingDiscard)
        #expect(discard.menuCategory == nil)
        #expect(model.state.screen.isConfirmingDiscard)
        #expect(!model.state.screen.isEditingMemo)
    }

    @Test
    func keepsOneShownAtATime() async throws {
        let model = try await Self.newModel()
        let category = try #require(model.output.categories.first)

        model.state.openMenu(for: category)
        model.state.open(.editCategory(category))
        let sheet = model.state.screen
        model.state.screen.isConfirmingDiscard = false
        let kept = model.state.screen.shown
        model.state.screen.sheet = nil

        #expect(sheet.shown == .sheet(.editCategory(category)))
        #expect(sheet.menuCategory == nil)
        #expect(kept == .sheet(.editCategory(category)))
        #expect(model.state.screen.shown == nil)
    }

    @Test
    func opensAndShowsBillsOfWalletDeck() async throws {
        let model = try await Self.newModel()

        model.state.openBills(true)
        model.state.showBills(true)
        let shown = model.state.screen.wallets
        model.state.openBills(false)

        #expect(shown.isBillOpen)
        #expect(shown.isBillShown)
        #expect(!model.state.screen.wallets.isBillOpen)
        #expect(model.state.screen.wallets.isBillShown)
    }
}
