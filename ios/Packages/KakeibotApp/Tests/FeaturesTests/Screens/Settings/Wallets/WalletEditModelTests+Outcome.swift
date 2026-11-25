import Core
@testable import FeatureModels
import Foundation
import Store
import Testing

extension WalletEditModelTests {
    @Test
    func placesSavedWalletInOutcome() async throws {
        let setup = try await Setup()
        let model = WalletEditModel(parts: .system(setup.database))
        model.state.name = "へそくり"

        let saved = await model.save()
        let outcome = try #require(model.state.outcome.value)

        #expect(saved != nil)
        #expect(outcome.saved?.id == saved?.id)
        #expect(outcome.closes)
        #expect(!model.state.payment.isAsking)
        #expect(model.state.payment.addedWallet == nil)
    }

    @Test
    func asksPaymentBeforeClosingAddedCard() async throws {
        let setup = try await Setup()
        let model = WalletEditModel(parts: .system(setup.database))
        model.state.name = "楽天カード"
        model.state.setKind(.card)

        let saved = try #require(await model.save())
        let asked = model.state.outcome.value
        let isAsking = model.state.payment.isAsking
        model.finishAddedWallet()
        let outcome = try #require(model.state.outcome.value)

        #expect(asked == nil)
        #expect(isAsking)
        #expect(model.state.payment.addedWallet?.id == saved.id)
        #expect(outcome.saved?.id == saved.id)
        #expect(outcome.closes)
    }

    @Test
    func placesNoOutcomeWhenSavingFails() async throws {
        let setup = try await Setup()
        let model = WalletEditModel(parts: .system(setup.database))
        model.state.name = "楽天カード"
        model.state.setKind(.card)
        try await setup.database.failWrites(to: "wallet")

        let saved = await model.save()

        #expect(saved == nil)
        #expect(model.state.outcome.value == nil)
        #expect(!model.state.payment.isAsking)
        #expect(model.state.errorNotice.message == "保存できませんでした")
    }

    @Test
    func placesSaveAndHideInOneOutcome() async throws {
        let setup = try await Setup()
        let bank = try await setup.wallet(named: "銀行")
        let model = WalletEditModel(parts: .system(setup.database), editing: bank.id)
        await model.load()
        model.state.name = "メインバンク"

        await model.saveTogglingHidden {
            await $0.save()
        }
        let outcome = try #require(model.state.outcome.value)

        #expect(outcome.saved?.name == "メインバンク")
        #expect(outcome.isHidden == true)
        #expect(outcome.closes)
        #expect(model.input.isHidden)
    }

    @Test
    func keepsSheetOpenWhenLastWalletCannotBeHidden() async throws {
        let setup = try await Setup()
        let wallets = try await setup.database.entryOptions().wallets
        let last = try #require(wallets.first)

        for wallet in wallets.dropFirst() {
            try await setup.database.setHidden(wallet.id, isHidden: true, at: Date())
        }

        let model = WalletEditModel(parts: .system(setup.database), editing: last.id)
        await model.load()

        let isHidden = await model.setHidden(true)

        #expect(!isHidden)
        #expect(model.state.outcome.value == nil)
        #expect(!model.input.isHidden)
        #expect(model.state.errorNotice.message == "最後の 1 つの口座は非表示にできません")
    }

    @Test
    func placesDeletionInOutcome() async throws {
        let setup = try await Setup()
        let adding = WalletEditModel(parts: .system(setup.database))
        adding.state.name = "へそくり"
        let saved = try #require(await adding.save())
        let model = WalletEditModel(parts: .system(setup.database), editing: saved.id)
        await model.load()

        let deletion = await model.delete()
        let outcome = try #require(model.state.outcome.value)

        #expect(deletion != nil)
        #expect(outcome.deletion?.id == deletion?.id)
        #expect(outcome.closes)
    }

    @Test
    func closesValuationDrawerAfterSaving() async throws {
        let setup = try await Setup()
        let model = try await Self.investment(in: setup)
        model.startValuation()
        model.state.open(.valuation)
        model.state.pressValuation(.digit(5))

        let isSaved = await model.saveValuation()

        #expect(isSaved)
        #expect(model.state.prompt.panel == nil)
    }

    @Test
    func keepsValuationDrawerOpenWhenSavingFails() async throws {
        let setup = try await Setup()
        let model = try await Self.investment(in: setup)
        model.startValuation()
        model.state.open(.valuation)
        model.state.pressValuation(.digit(5))
        try await setup.database.failWrites(to: "valuation")

        let isSaved = await model.saveValuation()

        #expect(!isSaved)
        #expect(model.state.prompt.panel == .valuation)
    }

    @Test
    func placesDeletedValuationInState() async throws {
        let setup = try await Setup()
        let model = try await Self.investment(in: setup)
        model.state.pressValuation(.digit(5))
        _ = await model.saveValuation()
        let valuation = try #require(model.input.valuations.first)

        let deletion = await model.deleteValuation(valuation.id)

        #expect(deletion != nil)
        #expect(model.state.valuationDeletion?.id == deletion?.id)
    }
}

private extension WalletEditModelTests {
    static func investment(in setup: Setup) async throws -> WalletEditModel {
        let adding = WalletEditModel(parts: .system(setup.database))

        adding.state.name = "積立"
        adding.state.setKind(.investment)

        let saved = try #require(await adding.save())
        let model = WalletEditModel(parts: .system(setup.database), editing: saved.id)

        await model.load()

        return model
    }
}
