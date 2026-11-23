import Core
import Features
import Foundation
import Store
import Testing

extension AssetsModelTests {
    @Test
    func pagesCardBillsByMonth() async throws {
        let setup = try await Setup()

        let wallet = WalletDraft(
            kind: .card,
            name: "カード",
            mark: .glyph(.card),
            color: "#4A6FA5",
            initialBalance: 0
        )

        let card = try await setup.database.saveWallet(wallet, at: Date())

        try await setup.save(.expense, 30000, on: "2026-09-20", from: card.id)
        try await setup.save(.expense, 12000, on: "2026-10-10", from: card.id)
        try await setup.save(.expense, 5000, on: "2026-10-20", from: card.id)
        try await setup.save(.income, 280_000, on: "2026-10-28", from: setup.bank)

        try await setup.save(
            .expense,
            800,
            on: "2026-10-05",
            from: card.id,
            billMonth: YearMonth("2026-12")
        )

        let draft = try RecurringDraft(
            type: .transfer,
            amount: 0,
            categoryId: nil,
            walletId: setup.bank,
            toWalletId: card.id,
            frequency: .monthly,
            month: 1,
            day: 27,
            closingDay: 31,
            startDate: #require(LocalDate("2026-10-01"))
        )

        try await setup.database.saveRecurring(draft, today: setup.today, at: Date())

        let model = AssetsModel(database: setup.database, today: setup.today)
        await model.load()
        let row = try #require(model.rows.first { $0.wallet.id == card.id })
        let unpaid = try #require(row.unpaid)
        let bills = row.bills

        #expect(model.billPages.map(\.month) == [YearMonth("2026-10"), YearMonth("2026-11")])
        #expect(model.upcomingBillTotal == 30000)
        #expect(model.shownUpcomingBills.map(\.bill.isOpen) == [false])
        #expect(bills.map(\.amount) == [30000, 17000])
        #expect(bills.map(\.isOpen) == [false, true])
        #expect(bills[1].balanceBefore == bills[0].balanceBefore + 250_000)
        #expect(unpaid.bills.map(\.total) == [30000, 12000])
        #expect(unpaid.bills.map(\.rows.count) == [1, 1])
        #expect(unpaid.later.map(\.amount) == [800])
        #expect(unpaid.total == 42800)

        model.billPage = 1

        #expect(model.upcomingBillTotal == 17000)
        #expect(model.shownBillPage?.isOpen == true)
        #expect(model.billPages.count == 2)
    }

    @Test
    func countsUnpaidEntriesOnceWithTwoCardBills() async throws {
        let setup = try await Setup()

        let wallet = WalletDraft(
            kind: .card,
            name: "カード",
            mark: .glyph(.card),
            color: "#4A6FA5",
            initialBalance: 0
        )

        let card = try await setup.database.saveWallet(wallet, at: Date())

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
            day: 27,
            closingDay: 31,
            startDate: #require(LocalDate("2026-10-01"))
        )

        try await setup.database.saveRecurring(draft, today: setup.today, at: Date())
        try await setup.database.saveRecurring(draft, today: setup.today, at: Date())

        let model = AssetsModel(database: setup.database, today: setup.today)
        await model.load()
        let row = try #require(model.rows.first { $0.wallet.id == card.id })
        let unpaid = try #require(row.unpaid)
        let ids = unpaid.bills.flatMap(\.rows).map(\.id) + unpaid.later.map(\.id)

        #expect(Set(ids).count == ids.count)
        #expect(unpaid.total == 42000)
    }
}
