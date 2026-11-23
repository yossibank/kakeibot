import Core
@testable import Features
import Foundation
import Store
import Testing

extension WalletEditModelTests {
    @Test
    func loadsAndEditsWallet() async throws {
        let setup = try await Setup()
        let bank = try await setup.wallet(named: "銀行")
        let model = WalletEditModel(database: setup.database, editing: bank.id)
        await model.load()
        let loaded = model.name
        let isChanged = model.isChanged

        model.name = "ゆうちょ"
        model.press(.clear)
        model.press(.digit(1))
        model.press(.digit(2))
        model.press(.doubleZero)
        model.press(.doubleZero)
        let saved = try #require(await model.save())

        #expect(loaded == "銀行")
        #expect(!isChanged)
        #expect(!model.needsHideConfirmation)
        #expect(saved.id == bank.id)
        #expect(saved.name == "ゆうちょ")
        #expect(saved.initialBalance == 120_000)
    }

    @Test
    func savesLoanAmountAndClearsItWhenKindChanges() async throws {
        let setup = try await Setup()
        let adding = WalletEditModel(database: setup.database)
        adding.name = "奨学金"
        adding.kind = .loan
        adding.pressLoanAmount(.digit(3))
        adding.pressLoanAmount(.doubleZero)
        adding.pressLoanAmount(.doubleZero)
        adding.pressLoanAmount(.digit(0))
        let saved = try #require(await adding.save())

        let model = WalletEditModel(database: setup.database, editing: saved.id)
        await model.load()
        let loaded = model.loanAmount.amount
        let isChanged = model.isChanged
        let repaid = model.repaidText
        model.kind = .bank
        let changed = try #require(await model.save())

        #expect(adding.showsLoanAmount)
        #expect(saved.loanAmount == 300_000)
        #expect(loaded == 300_000)
        #expect(!isChanged)
        #expect(repaid == "¥300,000 返済済み（100%）")
        #expect(!model.showsLoanAmount)
        #expect(changed.loanAmount == nil)
    }

    @Test
    func showsRepaidOnNewLoanOnlyAfterBalance() async throws {
        let setup = try await Setup()
        let model = WalletEditModel(database: setup.database)
        model.name = "奨学金"
        model.kind = .loan
        model.pressLoanAmount(.digit(3))
        model.pressLoanAmount(.doubleZero)
        model.pressLoanAmount(.doubleZero)
        model.pressLoanAmount(.digit(0))

        let beforeBalance = model.repaidText
        model.press(.digit(1))
        model.press(.doubleZero)
        model.press(.doubleZero)
        model.press(.digit(0))

        #expect(beforeBalance == nil)
        #expect(model.repaidText == "¥200,000 返済済み（66%）")
        #expect(model.isNegative)
        #expect(model.balanceText == "−¥100,000")
    }

    @Test
    func asksBeforeHidingWalletWithBalance() async throws {
        let setup = try await Setup()
        let bank = try await setup.wallet(named: "銀行")
        let options = try await setup.database.entryOptions()
        let salary = try #require(options.incomeCategories.first)
        let date = try #require(LocalDate("2026-10-01"))

        let income = EntryDraft(
            type: .income,
            amount: 5000,
            date: date,
            categoryId: salary.id,
            walletId: bank.id
        )

        try await setup.database.saveEntry(income, at: Date())
        let model = WalletEditModel(database: setup.database, editing: bank.id)
        await model.load()

        #expect(model.balance == 5000)
        #expect(model.needsHideConfirmation)
    }

    @Test
    func entrySheetSeesAddedWallet() async throws {
        let setup = try await Setup()
        let date = try #require(LocalDate("2026-10-12"))
        let entry = EntryModel(database: setup.database, date: date)
        await entry.load()

        let editor = entry.newWalletModel()
        editor.name = "楽天カード"
        editor.kind = .card
        let saved = try #require(await editor.save())
        await entry.reloadWallets()
        let wallet = try #require(entry.wallet(saved.id))

        #expect(wallet.name == "楽天カード")
        #expect(entry.balance(of: wallet) == 0)
    }

    @Test
    func refusesToHideTheLastWallet() async throws {
        let setup = try await Setup()
        let cash = try await setup.wallet(named: "財布")
        let bank = try await setup.wallet(named: "銀行")

        let bankModel = WalletEditModel(database: setup.database, editing: bank.id)
        let hid = await bankModel.setHidden(true)

        let cashModel = WalletEditModel(database: setup.database, editing: cash.id)
        let refused = await cashModel.setHidden(true)

        #expect(hid)
        #expect(!refused)
        #expect(cashModel.errorNotice.message == "最後の 1 つの口座は非表示にできません")
    }
}
