import Core
import Features
import Foundation
import Store
import Testing

extension AssetsModelTests {
    @Test
    func addsUpcomingRecurringsAndPlansUntilPeriodEnd() async throws {
        let setup = try await Setup()
        try await setup.save(.income, 1000, on: "2026-10-10", from: setup.cash)
        try await setup.save(.expense, 400, on: "2026-10-20", from: setup.cash)
        try await setup.save(.expense, 100, on: "2026-11-05", from: setup.cash)
        try await setup.saveRecurring(.income, 5000, day: 26, from: setup.bank)
        try await setup.saveRecurring(.expense, 300, day: 27, from: setup.bank)
        let model = AssetsModel(database: setup.database, today: setup.today)

        await model.load()

        #expect(model.outlook.end == LocalDate("2026-10-31"))
        #expect(model.outlook.items.map(\.change) == [-400, 5000, -300])
        #expect(model.outlook.items.map(\.balance) == [600, 5600, 5300])
        #expect(model.outlook.items.map(\.isRecurring) == [false, true, true])
        #expect(model.outlook.total == 5300)
        #expect(model.outlook.lowest?.balance == 600)
        #expect(model.outlook.later.map(\.change) == [-100])
        #expect(model.total == 1000)
    }

    @Test
    func leavesOutCardBillsFromOutlook() async throws {
        let setup = try await Setup()

        let wallet = WalletDraft(
            kind: .card,
            name: "カード",
            mark: .glyph(.card),
            color: "#4A6FA5",
            initialBalance: 0
        )

        let card = try await setup.database.saveWallet(wallet, at: Date())
        try await setup.save(.expense, 12000, on: "2026-10-10", from: card.id)
        try await setup.saveRecurring(.transfer, 0, day: 27, from: setup.bank, to: card.id)
        let model = AssetsModel(database: setup.database, today: setup.today)

        await model.load()

        #expect(model.outlook.items.isEmpty)
        #expect(!model.outlook.isShown)
    }

    @Test
    func findsDayWhenMoneyRunsShort() async throws {
        let setup = try await Setup()
        try await setup.save(.income, 1000, on: "2026-10-10", from: setup.cash)
        try await setup.saveRecurring(.expense, 3000, day: 27, from: setup.bank)
        try await setup.saveRecurring(.income, 5000, day: 28, from: setup.bank)
        let model = AssetsModel(database: setup.database, today: setup.today)

        await model.load()

        #expect(model.outlook.lowest?.date == LocalDate("2026-10-27"))
        #expect(model.outlook.lowest?.balance == -2000)
        #expect(model.outlook.total == 3000)
    }
}

extension AssetsModelTests.Setup {
    func saveRecurring(
        _ type: Entry.Kind,
        _ amount: Int,
        day: Int,
        from wallet: Wallet.ID,
        to destination: Wallet.ID? = nil
    ) async throws {
        let category: EntryCategory.ID? = switch type {
        case .expense: food
        case .income: salary
        case .transfer: nil
        }

        let draft = try RecurringDraft(
            type: type,
            amount: amount,
            categoryId: category,
            walletId: wallet,
            toWalletId: destination,
            frequency: .monthly,
            month: 1,
            day: day,
            closingDay: type == .transfer ? 15 : nil,
            startDate: #require(LocalDate("2026-10-01"))
        )

        try await database.saveRecurring(draft, today: today, at: Date())
    }
}
