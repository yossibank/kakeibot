import Core
import FeatureModels
import Features
import Foundation
import Store
import Testing

@MainActor
struct AssetsModelTests {
    @Test
    func sumsBalancesByWalletAndMonth() async throws {
        let setup = try await Setup()
        try await setup.save(.income, 250_000, on: "2026-09-25", from: setup.bank)
        try await setup.save(.expense, 980, on: "2026-10-01", from: setup.cash)
        try await setup.save(.transfer, 10000, on: "2026-10-02", from: setup.bank, to: setup.cash)

        let model = AssetsModel(parts: .system(setup.database), today: setup.today)
        await model.load()
        let balances = model.output.rows.map(\.balance)
        let totals = model.output.monthTotals.map(\.total)

        #expect(model.output.total == 249_020)
        #expect(balances == [9020, 240_000])
        #expect(model.output.changeFromLastMonth == -980)
        #expect(totals == [0, 0, 0, 0, 250_000, 249_020])
        #expect(model.output.monthTotals.last?.month == setup.today.yearMonth)
    }

    @Test
    func leavesOutFutureEntriesFromBalances() async throws {
        let setup = try await Setup()
        try await setup.save(.income, 1000, on: "2026-10-10", from: setup.cash)
        try await setup.save(.expense, 400, on: "2026-10-20", from: setup.cash)
        let model = AssetsModel(parts: .system(setup.database), today: setup.today)

        await model.load()

        #expect(model.output.rows.first?.balance == 1000)
        #expect(model.output.total == 1000)
    }

    @Test
    func listsFutureEntriesAsPlans() async throws {
        let setup = try await Setup()
        try await setup.save(.income, 1000, on: "2026-10-10", from: setup.cash)
        try await setup.save(.income, 5000, on: "2026-10-25", from: setup.bank)
        try await setup.save(.expense, 400, on: "2026-10-20", from: setup.cash)
        try await setup.save(.transfer, 300, on: "2026-10-18", from: setup.bank, to: setup.cash)
        let model = AssetsModel(parts: .system(setup.database), today: setup.today)

        await model.load()

        #expect(model.output.plans.map(\.change) == [-400, 5000])
        #expect(model.output.plans.first?.date == LocalDate("2026-10-20"))
        #expect(model.output.plans.first?.wallet == "財布")
        #expect(model.output.total == 1000)
    }

    @Test
    func listsUpcomingCardBills() async throws {
        let setup = try await Setup()

        let wallet = WalletDraft(
            kind: .card,
            name: "カード",
            mark: .glyph(.card),
            color: "#4A6FA5",
            initialBalance: 0
        )

        let card = try await setup.database.save(wallet, at: Date())

        try await setup.save(
            .expense,
            30000,
            on: "2026-09-20",
            from: card.id
        )

        try await setup.save(
            .expense,
            12000,
            on: "2026-10-10",
            from: card.id
        )

        try await setup.save(
            .expense,
            500,
            on: "2026-09-10",
            from: card.id,
            billMonth: YearMonth("2026-10")
        )

        try await setup.save(
            .expense,
            800,
            on: "2026-10-12",
            from: card.id,
            billMonth: YearMonth("2026-11")
        )

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

        try await setup.database.saveRecurring(draft, today: setup.today, at: Date())

        let model = AssetsModel(parts: .system(setup.database), today: setup.today)
        await model.load()
        let row = try #require(model.output.upcomingBills.first)
        let bill = row.bill
        let from = try #require(LocalDate("2026-09-16"))
        let through = try #require(LocalDate("2026-10-15"))

        #expect(bill.date == LocalDate("2026-10-26"))
        #expect(bill.amount == 42500)
        #expect(bill.period == from...through)
        #expect(model.output.upcomingBillTotal == 42500)
        #expect(row.source == "銀行")
        #expect(row.movedIn.map(\.amount) == [500])
        #expect(row.movedOut.map(\.amount) == [800])
        #expect(bill.balanceAfter == -42500)
        #expect(bill.shortage == 42500)
        #expect(model.output.rows.last?.nextBill?.amount == 42500)
        #expect(model.output.holdings.unpaid == 43300)
        #expect(model.output.sections.map(\.role) == [.onHand, .card])
    }

    @Test
    func estimatesLoanPayoff() async throws {
        let setup = try await Setup()

        let wallet = WalletDraft(
            kind: .loan,
            name: "奨学金",
            mark: .glyph(.contract),
            color: "#4A6FA5",
            initialBalance: -100_000
        )

        let loan = try await setup.database.save(wallet, at: Date())
        try await setup.save(.transfer, 30000, on: "2026-10-20", from: setup.bank, to: loan.id)

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

        try await setup.database.saveRecurring(draft, today: setup.today, at: Date())

        let model = AssetsModel(parts: .system(setup.database), today: setup.today)
        await model.load()
        let row = try #require(model.output.rows.first { $0.wallet.id == loan.id })
        let lastDate = try #require(LocalDate("2027-01-27"))
        let payoff = LoanPayoff(count: 4, lastDate: lastDate)

        #expect(row.repayment == .until(payoff))
        #expect(model.output.rows.first?.repayment == nil)
    }
}

extension AssetsModelTests {
    @Test
    func countsCardsInTotal() async throws {
        let setup = try await Setup()

        let wallet = WalletDraft(
            kind: .card,
            name: "カード",
            mark: .glyph(.card),
            color: "#4A6FA5",
            initialBalance: 0
        )

        let card = try await setup.database.save(wallet, at: Date())
        try await setup.save(.income, 50000, on: "2026-10-01", from: setup.cash)
        try await setup.save(.expense, 3000, on: "2026-10-05", from: card.id)
        let model = AssetsModel(parts: .system(setup.database), today: setup.today)

        await model.load()

        #expect(model.output.holdings.onHand == 50000)
        #expect(model.output.holdings.unpaid == 3000)
        #expect(model.output.total == 47000)
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
        let today = try #require(LocalDate("2026-10-15"))

        try database.insertDefaultsIfEmpty(at: Date())

        let options = try await database.entryOptions()

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
        to destination: Wallet.ID? = nil,
        billMonth: YearMonth? = nil
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
            toWalletId: destination,
            billMonth: billMonth
        )

        try await database.saveEntry(draft, at: Date())
    }
}
