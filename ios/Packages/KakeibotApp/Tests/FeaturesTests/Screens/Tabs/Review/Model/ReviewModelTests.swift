import Core
import Features
import Foundation
import Observation
import Store
import Synchronization
import Testing
import TestSupport

@MainActor
struct ReviewModelTests {
    @Test
    func comparesWithPreviousMonth() async throws {
        let setup = try await RecordsModelTests.Setup()
        try await setup.save(.expense, amount: 980, on: "2026-10-12")
        try await setup.save(.expense, amount: 3000, on: "2026-10-05")
        try await setup.save(.income, amount: 250_000, on: "2026-10-10")
        try await setup.save(.expense, amount: 5000, on: "2026-09-10")
        try await setup.save(.expense, amount: 7000, on: "2026-09-20")
        let model = ReviewModel(database: setup.database, today: setup.today)

        try await observe(model) {
            model.list != nil
        }

        let expense = model.total
        let expenseChange = model.change
        let incomeChange = model.change(of: .income)
        model.setKind(.balance)
        let balance = model.total

        #expect(expense == 3980)
        #expect(expenseChange == -1020)
        #expect(incomeChange == 250_000)
        #expect(balance == 246_020)
    }

    @Test
    func comparesWholePreviousMonthWhenFinished() async throws {
        let setup = try await RecordsModelTests.Setup()
        try await setup.save(.expense, amount: 3000, on: "2026-09-05")
        try await setup.save(.expense, amount: 7000, on: "2026-09-20")
        let model = ReviewModel(database: setup.database, today: setup.today)

        try await observe(model) {
            model.list != nil
        }

        model.move(by: -1)

        #expect(!model.isComparingPartially)
        #expect(model.change == 7000 + 3000)
    }

    @Test
    func knowsWhetherPreviousPeriodHasEntries() async throws {
        let setup = try await RecordsModelTests.Setup()
        try await setup.save(.expense, amount: 980, on: "2026-10-05")
        try await setup.save(.income, amount: 3000, on: "2026-09-03")
        let model = ReviewModel(database: setup.database, today: setup.today)

        try await observe(model) {
            model.list != nil
        }

        let hasPreviousNow = model.hasPreviousEntries
        model.move(by: -1)
        let hasPreviousLastMonth = model.hasPreviousEntries

        #expect(hasPreviousNow)
        #expect(!hasPreviousLastMonth)
    }

    @Test
    func countsMovesToArchivedWalletInPastPeriod() async throws {
        let setup = try await RecordsModelTests.Setup()
        let now = Date()

        let wallet = WalletDraft(
            kind: .loan,
            name: "奨学金",
            mark: .glyph(.contract),
            color: "#4A6FA5",
            initialBalance: -1_200_000
        )

        let loan = try await setup.database.save(wallet, at: now)
        let options = try await setup.database.entryOptions()

        let draft = try EntryDraft(
            type: .transfer,
            amount: 30000,
            date: #require(LocalDate("2026-09-10")),
            categoryId: nil,
            walletId: options.wallets[0].id,
            toWalletId: loan.id
        )

        try await setup.database.saveEntry(draft, at: now)
        try await setup.database.setHidden(loan.id, isHidden: true, at: now)
        let model = ReviewModel(database: setup.database, today: setup.today)

        try await observe(model) {
            model.list != nil
        }

        model.move(by: -1)

        #expect(ReviewModel.total(of: model.moves) == 30000)
        #expect(model.moves.map(\.wallet.id) == [loan.id])
    }

    @Test
    func leavesOutFutureRepaymentsFromPayoff() async throws {
        let setup = try await RecordsModelTests.Setup()
        let now = Date()

        let wallet = WalletDraft(
            kind: .loan,
            name: "奨学金",
            mark: .glyph(.contract),
            color: "#4A6FA5",
            initialBalance: -100_000
        )

        let loan = try await setup.database.save(wallet, at: now)
        let options = try await setup.database.entryOptions()

        for text in ["2026-10-10", "2026-10-20"] {
            let draft = try EntryDraft(
                type: .transfer,
                amount: 30000,
                date: #require(LocalDate(text)),
                categoryId: nil,
                walletId: options.wallets[0].id,
                toWalletId: loan.id
            )

            try await setup.database.saveEntry(draft, at: now)
        }

        let recurring = try RecurringDraft(
            type: .transfer,
            amount: 30000,
            categoryId: nil,
            walletId: options.wallets[0].id,
            toWalletId: loan.id,
            frequency: .monthly,
            month: 1,
            day: 27,
            startDate: #require(LocalDate("2026-10-16"))
        )

        try await setup.database.saveRecurring(recurring, today: setup.today, at: now)

        let model = ReviewModel(database: setup.database, today: setup.today)

        try await observe(model) {
            model.list != nil && !model.moves.isEmpty
        }

        let move = try #require(model.moves.first)

        #expect(move.balance == -70000)
    }

    @Test
    func cachedMovesStillWatchRecurrings() async throws {
        let setup = try await RecordsModelTests.Setup()
        let now = Date()
        let notified = Mutex(false)

        let wallet = WalletDraft(
            kind: .loan,
            name: "奨学金",
            mark: .glyph(.contract),
            color: "#4A6FA5",
            initialBalance: -100_000
        )

        let loan = try await setup.database.save(wallet, at: now)
        let options = try await setup.database.entryOptions()

        let draft = try EntryDraft(
            type: .transfer,
            amount: 30000,
            date: #require(LocalDate("2026-10-10")),
            categoryId: nil,
            walletId: options.wallets[0].id,
            toWalletId: loan.id
        )

        try await setup.database.saveEntry(draft, at: now)

        let recurring = try RecurringDraft(
            type: .transfer,
            amount: 30000,
            categoryId: nil,
            walletId: options.wallets[0].id,
            toWalletId: loan.id,
            frequency: .monthly,
            month: 1,
            day: 27,
            startDate: #require(LocalDate("2027-01-01"))
        )

        let model = ReviewModel(database: setup.database, today: setup.today)

        let task = Task {
            await model.run()
        }

        await ObservationWait.until {
            !model.moves.isEmpty
        }
        #expect(model.moves.first?.payoff == nil)

        withObservationTracking {
            _ = model.moves
        } onChange: {
            notified.withLock { $0 = true }
        }

        try await setup.database.saveRecurring(recurring, today: setup.today, at: now)

        await ObservationWait.until {
            _ = model.moves

            return notified.withLock { $0 }
        }

        task.cancel()

        #expect(model.moves.first?.payoff != nil)
    }
}

extension ReviewModelTests {
    func observe(
        _ model: ReviewModel,
        sourceLocation: SourceLocation = #_sourceLocation,
        until isReady: @escaping @MainActor () -> Bool
    ) async throws {
        let task = Task {
            await model.run()
        }

        await ObservationWait.until(
            sourceLocation: sourceLocation,
            isReady
        )

        task.cancel()
    }
}

extension RecordsModelTests.Setup {
    func saveDaily(
        amount: Int,
        on text: String
    ) async throws {
        let options = try await database.entryOptions()
        let date = try #require(LocalDate(text))

        let draft = EntryDraft(
            type: .expense,
            amount: amount,
            date: date,
            categoryId: options.expenseCategories[1].id,
            walletId: options.wallets[0].id,
            memo: ""
        )

        try await database.saveEntry(draft, at: Date())
    }
}
