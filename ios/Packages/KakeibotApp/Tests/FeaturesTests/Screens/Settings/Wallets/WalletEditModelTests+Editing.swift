import Core
@testable import FeatureModels
@testable import Features
import Foundation
import Store
import Testing

extension WalletEditModelTests {
    @Test
    func loadsAndEditsWallet() async throws {
        let setup = try await Setup()
        let bank = try await setup.wallet(named: "銀行")
        let model = WalletEditModel(database: setup.database, clock: .system, editing: bank.id)
        await model.load()
        let loaded = model.state.name
        let isChanged = model.isChanged

        model.state.name = "ゆうちょ"
        model.state.press(.clear)
        model.state.press(.digit(1))
        model.state.press(.digit(2))
        model.state.press(.doubleZero)
        model.state.press(.doubleZero)
        let saved = try #require(await model.save())

        #expect(loaded == "銀行")
        #expect(!isChanged)
        #expect(!model.output.needsHideConfirmation)
        #expect(saved.id == bank.id)
        #expect(saved.name == "ゆうちょ")
        #expect(saved.initialBalance == 120_000)
    }

    @Test
    func savesLoanAmountAndClearsItWhenKindChanges() async throws {
        let setup = try await Setup()
        let adding = WalletEditModel(database: setup.database, clock: .system)
        adding.state.name = "奨学金"
        adding.state.setKind(.loan)
        adding.state.pressLoanAmount(.digit(3))
        adding.state.pressLoanAmount(.doubleZero)
        adding.state.pressLoanAmount(.doubleZero)
        adding.state.pressLoanAmount(.digit(0))
        let saved = try #require(await adding.save())

        let model = WalletEditModel(database: setup.database, clock: .system, editing: saved.id)
        await model.load()
        let loaded = model.state.loanAmount.amount
        let isChanged = model.isChanged
        let repaid = model.output.repaidText
        model.state.setKind(.bank)
        let changed = try #require(await model.save())

        #expect(adding.output.showsLoanAmount)
        #expect(saved.loanAmount == 300_000)
        #expect(loaded == 300_000)
        #expect(!isChanged)
        #expect(repaid == "¥300,000 返済済み（100%）")
        #expect(!model.output.showsLoanAmount)
        #expect(changed.loanAmount == nil)
    }

    @Test
    func showsRepaidOnNewLoanOnlyAfterBalance() async throws {
        let setup = try await Setup()
        let model = WalletEditModel(database: setup.database, clock: .system)
        model.state.name = "奨学金"
        model.state.setKind(.loan)
        model.state.pressLoanAmount(.digit(3))
        model.state.pressLoanAmount(.doubleZero)
        model.state.pressLoanAmount(.doubleZero)
        model.state.pressLoanAmount(.digit(0))

        let beforeBalance = model.output.repaidText
        model.state.press(.digit(1))
        model.state.press(.doubleZero)
        model.state.press(.doubleZero)
        model.state.press(.digit(0))

        #expect(beforeBalance == nil)
        #expect(model.output.repaidText == "¥200,000 返済済み（66%）")
        #expect(model.state.isNegative)
        #expect(model.output.balanceText == "−¥100,000")
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
        let model = WalletEditModel(database: setup.database, clock: .system, editing: bank.id)
        await model.load()

        #expect(model.input.balance == 5000)
        #expect(model.output.needsHideConfirmation)
    }

    @Test
    func entrySheetSeesAddedWallet() async throws {
        let setup = try await Setup()
        let date = try #require(LocalDate("2026-10-12"))
        let entry = EntryModel(database: setup.database, clock: .system, date: date)
        await entry.load()

        let editor = entry.newWalletModel()
        editor.state.name = "楽天カード"
        editor.state.setKind(.card)
        let saved = try #require(await editor.save())
        await entry.reloadWallets()
        let wallet = try #require(entry.output.wallet(saved.id))

        #expect(wallet.name == "楽天カード")
        #expect(entry.output.balance(of: wallet) == 0)
    }

    @Test
    func refusesToHideTheLastWallet() async throws {
        let setup = try await Setup()
        let cash = try await setup.wallet(named: "財布")
        let bank = try await setup.wallet(named: "銀行")

        let bankModel = WalletEditModel(database: setup.database, clock: .system, editing: bank.id)
        let hid = await bankModel.setHidden(true)

        let cashModel = WalletEditModel(database: setup.database, clock: .system, editing: cash.id)
        let refused = await cashModel.setHidden(true)

        #expect(hid)
        #expect(!refused)
        #expect(cashModel.state.errorNotice.message == "最後の 1 つの口座は非表示にできません")
    }
}
