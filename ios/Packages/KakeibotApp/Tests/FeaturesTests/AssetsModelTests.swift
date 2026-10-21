import Core
import Features
import Foundation
import Store
import Testing

@MainActor
struct AssetsModelTests {
    @Test
    func sumsBalancesByWalletAndMonth() async throws {
        let setup = try await Setup()

        try await setup.save(
            .income,
            250_000,
            on: "2026-09-25",
            from: setup.bank
        )

        try await setup.save(.expense, 980, on: "2026-10-01", from: setup.cash)

        try await setup.save(
            .transfer,
            10000,
            on: "2026-10-02",
            from: setup.bank,
            to: setup.cash
        )

        let model = AssetsModel(database: setup.database, today: setup.today)
        await model.load()
        let balances = model.rows.map(\.balance)
        let totals = model.monthTotals.map(\.total)

        #expect(model.total == 249_020)
        #expect(balances == [9020, 240_000])
        #expect(model.changeFromLastMonth == -980)
        #expect(totals == [0, 0, 0, 0, 250_000, 249_020])
        #expect(model.monthTotals.last?.month == setup.today.yearMonth)
    }

    @Test
    func listsUpcomingCardBills() async throws {
        let setup = try await Setup()

        let card = try await setup.database.saveWallet(
            WalletDraft(
                kind: .card,
                name: "カード",
                mark: .glyph(.card),
                color: "#4A6FA5",
                initialBalance: 0
            ),
            at: Date()
        )

        try await setup.save(.expense, 30000, on: "2026-09-20", from: card.id)
        try await setup.save(.expense, 12000, on: "2026-10-10", from: card.id)

        let draft = try RecurringDraft(
            type: .transfer,
            amount: 0,
            categoryId: nil,
            walletId: setup.bank,
            toWalletId: card.id,
            frequency: .monthly,
            month: 1,
            day: 26,
            closingDay: 15,
            startDate: #require(LocalDate("2026-10-01"))
        )

        try await setup.database.saveRecurring(
            draft,
            today: setup.today,
            at: Date()
        )

        let model = AssetsModel(database: setup.database, today: setup.today)
        await model.load()
        let row = try #require(model.upcomingBills.first)
        let bill = row.bill
        let from = try #require(LocalDate("2026-09-16"))
        let through = try #require(LocalDate("2026-10-15"))

        #expect(bill.date == LocalDate("2026-10-26"))
        #expect(bill.amount == 42000)
        #expect(bill.period == from...through)
        #expect(model.upcomingBillTotal == 42000)
        #expect(row.source == "銀行")
        #expect(bill.balanceAfter == -42000)
        #expect(bill.shortage == 42000)
        #expect(model.rows.last?.nextBill?.amount == 42000)
        #expect(model.holdings.unpaid == 42000)
        #expect(model.sections.map(\.role) == [.onHand, .card])
    }

    @Test
    func estimatesLoanPayoff() async throws {
        let setup = try await Setup()

        let loan = try await setup.database.saveWallet(
            WalletDraft(
                kind: .loan,
                name: "奨学金",
                mark: .glyph(.contract),
                color: "#4A6FA5",
                initialBalance: -100_000
            ),
            at: Date()
        )

        let draft = try RecurringDraft(
            type: .transfer,
            amount: 30000,
            categoryId: nil,
            walletId: setup.bank,
            toWalletId: loan.id,
            frequency: .monthly,
            month: 1,
            day: 27,
            startDate: #require(LocalDate("2026-10-16"))
        )

        try await setup.database.saveRecurring(
            draft,
            today: setup.today,
            at: Date()
        )

        let model = AssetsModel(database: setup.database, today: setup.today)
        await model.load()
        let row = try #require(model.rows.first { $0.wallet.id == loan.id })
        let lastDate = try #require(LocalDate("2027-01-27"))
        let payoff = LoanPayoff(count: 4, lastDate: lastDate)

        #expect(row.repayment == .until(payoff))
        #expect(model.rows.first?.repayment == nil)
    }
}

extension AssetsModelTests {
    struct Setup {
        let database: AppDatabase
        let today: LocalDate
        let cash: Wallet.ID
        let bank: Wallet.ID
        let food: EntryCategory.ID
        let salary: EntryCategory.ID
    }
}

extension AssetsModelTests.Setup {
    init() async throws {
        let database = try AppDatabase.inMemory()
        try database.insertDefaultsIfEmpty(at: Date())
        let options = try await database.entryOptions()
        let today = try #require(LocalDate("2026-10-15"))

        self.init(
            database: database,
            today: today,
            cash: options.wallets[0].id,
            bank: options.wallets[1].id,
            food: options.expenseCategories[0].id,
            salary: options.incomeCategories[0].id
        )
    }

    func save(
        _ type: Entry.Kind,
        _ amount: Int,
        on text: String,
        from wallet: Wallet.ID,
        to destination: Wallet.ID? = nil
    ) async throws {
        let date = try #require(LocalDate(text))

        let category: EntryCategory.ID? = switch type {
        case .expense: food
        case .income: salary
        case .transfer: nil
        }

        let draft = EntryDraft(
            type: type,
            amount: amount,
            date: date,
            categoryId: category,
            walletId: wallet,
            toWalletId: destination
        )

        try await database.saveEntry(draft, at: Date())
    }
}
