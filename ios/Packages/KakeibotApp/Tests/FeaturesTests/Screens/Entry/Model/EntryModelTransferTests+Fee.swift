import Core
import Features
import Foundation
import Store
import Testing

extension EntryModelTransferTests {
    @Test
    func savesFeeTypedOnKeypad() async throws {
        let setup = try await Setup()
        let model = EntryModel(
            database: setup.database,
            clock: .system,
            date: setup.date,
            type: .transfer
        )

        await model.load()
        model.state.press(.digit(5))
        model.state.press(.doubleZero)
        model.state.press(.digit(0))
        model.state.enter(.fee)
        model.state.press(.digit(1))
        model.state.press(.digit(1))
        model.state.press(.digit(0))

        let saved = await model.save()
        let fee = try #require(saved?.fee)

        #expect(model.output.amount == 5000)
        #expect(fee.amount == 110)
        #expect(fee.walletId == setup.cash)
        #expect(fee.transferId == saved?.entry.id)
    }

    @Test
    func putsUsedFeesFirst() async throws {
        let setup = try await Setup()

        let draft = EntryDraft(
            type: .transfer,
            amount: 10000,
            date: setup.date,
            categoryId: nil,
            walletId: setup.bank,
            toWalletId: setup.cash,
            fee: 165
        )

        try await setup.database.saveEntry(draft, at: Date())
        let model = EntryModel(
            database: setup.database,
            clock: .system,
            date: setup.date,
            type: .transfer
        )

        await model.load()

        #expect(model.output.feeChoices == [165, 110, 220, 330])
    }

    @Test
    func countsFeeInSourceBalance() async throws {
        let setup = try await Setup()
        let date = try #require(LocalDate("2026-10-01"))

        let income = EntryDraft(
            type: .income,
            amount: 3000,
            date: date,
            categoryId: setup.salary,
            walletId: setup.cash
        )

        try await setup.database.saveEntry(income, at: Date())
        let model = EntryModel(
            database: setup.database,
            clock: .system,
            date: setup.date,
            type: .transfer
        )

        await model.load()
        model.state.press(.digit(3))
        model.state.press(.doubleZero)
        model.state.press(.digit(0))
        model.state.setFee(110)

        #expect(model.output.isOverSourceBalance)
    }

    @Test
    func opensTransferFromFee() async throws {
        let setup = try await Setup()

        let draft = EntryDraft(
            type: .transfer,
            amount: 10000,
            date: setup.date,
            categoryId: nil,
            walletId: setup.bank,
            toWalletId: setup.cash,
            fee: 220
        )

        let transfer = try await setup.database.saveEntry(draft, at: Date())
        let fee = try #require(try await setup.database.fee(of: transfer.id))
        let model = EntryModel(
            database: setup.database,
            clock: .system,
            editing: fee.id,
            date: setup.date
        )

        await model.load()
        let after = model.output.wallet(setup.bank).flatMap { model.output.afterLine(
            of: $0,
            isSource: true
        ) }
        model.state.setFee(330)
        let saved = await model.save()

        #expect(model.state.type == .transfer)
        #expect(model.output.amount == 10000)
        #expect(saved?.entry.id == transfer.id)
        #expect(saved?.fee?.id == fee.id)
        #expect(saved?.fee?.amount == 330)
        #expect(after?.amount == -10220)
    }

    @Test
    func dropsFeeWhenRecordingAgain() async throws {
        let setup = try await Setup()

        let draft = EntryDraft(
            type: .transfer,
            amount: 10000,
            date: setup.date,
            categoryId: nil,
            walletId: setup.bank,
            toWalletId: setup.cash,
            fee: 220
        )

        let transfer = try await setup.database.saveEntry(draft, at: Date())
        let model = EntryModel(
            database: setup.database,
            clock: .system,
            editing: transfer.id,
            date: setup.date
        )
        await model.load()

        await model.recordAgain()
        let saved = await model.save()

        #expect(saved?.entry.id != transfer.id)
        #expect(saved?.entry.amount == 10000)
        #expect(saved?.fee == nil)
    }
}
