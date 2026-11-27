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
        model.state.fields.name = "へそくり"

        await model.flow.save().value
        let outcome = try #require(model.flow.state.outcome.value)
        let wallets = try await setup.database.entryOptions().wallets

        #expect(wallets.contains { $0.id == outcome.saved?.id })
        #expect(outcome.saved?.name == "へそくり")
        #expect(outcome.closes)
        #expect(!model.state.presented.paymentStep.isShowing(.asking))
        #expect(model.state.presented.addedWallet == nil)
    }

    @Test
    func asksPaymentBeforeClosingAddedCard() async throws {
        let setup = try await Setup()
        let model = WalletEditModel(parts: .system(setup.database))
        model.state.fields.name = "楽天カード"
        model.state.setKind(.card)

        await model.flow.save().value
        let saved = try #require(model.state.presented.addedWallet)
        let asked = model.flow.state.outcome.value
        let isAsking = model.state.presented.paymentStep.isShowing(.asking)
        model.finishAddedWallet()
        let outcome = try #require(model.flow.state.outcome.value)

        #expect(asked == nil)
        #expect(isAsking)
        #expect(model.state.presented.addedWallet?.id == saved.id)
        #expect(outcome.saved?.id == saved.id)
        #expect(outcome.closes)
    }

    @Test
    func placesNoOutcomeWhenSavingFails() async throws {
        let setup = try await Setup()
        let model = WalletEditModel(parts: .system(setup.database))
        model.state.fields.name = "楽天カード"
        model.state.setKind(.card)
        try await setup.database.failWrites(to: "wallet")

        await model.flow.save().value

        #expect(model.state.presented.addedWallet == nil)
        #expect(model.flow.state.outcome.value == nil)
        #expect(!model.state.presented.paymentStep.isShowing(.asking))
        #expect(model.state.notices.error.message == "保存できませんでした")
    }

    @Test
    func placesSaveAndHideInOneOutcome() async throws {
        let setup = try await Setup()
        let bank = try await setup.wallet(named: "銀行")
        let model = WalletEditModel(parts: .system(setup.database), editing: bank.id)
        await model.load()
        model.state.fields.name = "メインバンク"

        await model.flow.saveTogglingHidden().value
        let outcome = try #require(model.flow.state.outcome.value)

        #expect(outcome.saved?.name == "メインバンク")
        #expect(outcome.isHidden == true)
        #expect(outcome.closes)
        #expect(model.flow.output.isHidden)
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

        await model.flow.setHidden(true).value

        #expect(model.flow.state.outcome.value == nil)
        #expect(!model.flow.output.isHidden)
        #expect(model.state.notices.error.message == "最後の 1 つの口座は非表示にできません")
    }

    @Test
    func placesDeletionInOutcome() async throws {
        let setup = try await Setup()
        let adding = WalletEditModel(parts: .system(setup.database))
        adding.state.fields.name = "へそくり"
        let saved = try #require(await adding.save())
        let model = WalletEditModel(parts: .system(setup.database), editing: saved.id)
        await model.load()

        await model.flow.delete().value
        let outcome = try #require(model.flow.state.outcome.value)
        let wallets = try await setup.database.entryOptions().wallets

        #expect(outcome.deletion != nil)
        #expect(!wallets.contains { $0.id == saved.id })
        #expect(outcome.closes)
    }

    @Test
    func closesValuationDrawerAfterSaving() async throws {
        let setup = try await Setup()
        let model = try await Self.investment(in: setup)
        model.startValuation()
        model.state.presented.panel.show(.valuation)
        model.state.pressValuation(.digit(5))

        let isSaved = await model.saveValuation()

        #expect(isSaved)
        #expect(model.state.presented.panel.current == nil)
    }

    @Test
    func keepsValuationDrawerOpenWhenSavingFails() async throws {
        let setup = try await Setup()
        let model = try await Self.investment(in: setup)
        model.startValuation()
        model.state.presented.panel.show(.valuation)
        model.state.pressValuation(.digit(5))
        try await setup.database.failWrites(to: "valuation")

        let isSaved = await model.saveValuation()

        #expect(!isSaved)
        #expect(model.state.presented.panel.current == .valuation)
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
        #expect(model.state.notices.valuationDeletion.current?.id == deletion?.id)
    }
}

private extension WalletEditModelTests {
    static func investment(in setup: Setup) async throws -> WalletEditModel {
        let adding = WalletEditModel(parts: .system(setup.database))

        adding.state.fields.name = "積立"
        adding.state.setKind(.investment)

        let saved = try #require(await adding.save())
        let model = WalletEditModel(parts: .system(setup.database), editing: saved.id)

        await model.load()

        return model
    }
}
