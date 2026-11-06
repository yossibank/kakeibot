import Core
import Features
import Foundation
import Store
import Testing

extension EntryModelTransferTests {
    @Test
    func savesFeeTypedOnKeypad() async throws {
        let setup = try await Setup()
        let model = EntryModel(database: setup.database, date: setup.date, type: .transfer)

        await model.load()
        model.press(.digit(5))
        model.press(.doubleZero)
        model.press(.digit(0))
        model.enter(.fee)
        model.press(.digit(1))
        model.press(.digit(1))
        model.press(.digit(0))

        let saved = await model.save()
        let fee = try #require(saved?.fee)

        #expect(model.amount == 5000)
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
        let model = EntryModel(database: setup.database, date: setup.date, type: .transfer)

        await model.load()

        #expect(model.feeChoices == [165, 110, 220, 330])
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
        let model = EntryModel(database: setup.database, date: setup.date, type: .transfer)

        await model.load()
        model.press(.digit(3))
        model.press(.doubleZero)
        model.press(.digit(0))
        model.setFee(110)

        #expect(model.isOverSourceBalance)
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
        let model = EntryModel(database: setup.database, editing: fee.id, date: setup.date)

        await model.load()
        let after = model.wallet(setup.bank).flatMap { model.afterLine(of: $0, isSource: true) }
        model.setFee(330)
        let saved = await model.save()

        #expect(model.type == .transfer)
        #expect(model.amount == 10000)
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
        let model = EntryModel(database: setup.database, editing: transfer.id, date: setup.date)
        await model.load()

        await model.recordAgain()
        let saved = await model.save()

        #expect(saved?.entry.id != transfer.id)
        #expect(saved?.entry.amount == 10000)
        #expect(saved?.fee == nil)
    }
}
