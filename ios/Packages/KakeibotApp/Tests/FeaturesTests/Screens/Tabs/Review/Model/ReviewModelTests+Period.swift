import Core
import Features
import Foundation
import Observation
import Store
import Synchronization
import Testing
import TestSupport

extension ReviewModelTests {
    @Test
    func totalsUpcomingRecurringsOfCurrentPeriod() async throws {
        let setup = try await RecordsModelTests.Setup()
        let options = try await setup.database.entryOptions()

        let recurring = try RecurringDraft(
            type: .expense,
            amount: 3000,
            categoryId: options.expenseCategories[0].id,
            walletId: options.wallets[0].id,
            toWalletId: nil,
            frequency: .monthly,
            month: 1,
            day: 27,
            startDate: #require(LocalDate("2026-10-01"))
        )

        try await setup.database.saveRecurring(recurring, today: setup.today, at: Date())

        let model = ReviewModel(database: setup.database, today: setup.today)

        try await observe(model) {
            model.list != nil && model.upcomingRecurringTotal != nil
        }

        #expect(model.upcomingRecurringTotal == 3000)

        model.setKind(.income)

        #expect(model.upcomingRecurringTotal == nil)

        model.setKind(.expense)
        model.move(by: -1)

        #expect(model.upcomingRecurringTotal == nil)
    }

    @Test
    func ranksCategoriesByAmount() async throws {
        let setup = try await RecordsModelTests.Setup()
        let options = try await setup.database.entryOptions()
        let food = options.expenseCategories[0]
        let daily = options.expenseCategories[1]
        try await setup.save(.expense, amount: 500, on: "2026-10-12")
        try await setup.save(.expense, amount: 1500, on: "2026-10-13")
        try await setup.saveDaily(amount: 6000, on: "2026-10-14")
        let month = try #require(YearMonth("2026-10"))
        try await setup.database.setBudget(4000, for: food.id, from: month)
        let model = ReviewModel(database: setup.database, today: setup.today)

        try await observe(model) {
            model.list != nil && !model.budgets.isEmpty
        }

        let shares = model.categoryShares

        #expect(shares.map(\.name) == [daily.name, food.name])
        #expect(shares.map(\.amount) == [6000, 2000])
        #expect(shares.map(\.ratio) == [0.75, 0.25])
        #expect(shares.last?.usage?.remaining == 2000)
        #expect(shares.first?.usage == nil)

        let foodShare = try #require(shares.last)
        let walletShare = try #require(model.walletShares.first)
        let foodRows = model.rows(for: foodShare)
        let walletRows = model.rows(for: walletShare)

        #expect(foodRows.map(\.amount) == [1500, 500])
        #expect(walletRows.map(\.amount) == [6000, 1500, 500])
    }

    @Test
    func movesOnlyUpToCurrentPeriod() async throws {
        let setup = try await RecordsModelTests.Setup()
        let model = ReviewModel(database: setup.database, today: setup.today)

        model.move(by: 1)
        let current = model.period.range
        model.move(by: -2)
        let earlier = model.period.range
        model.setScale(.year)
        let year = model.period.range

        #expect(current.lowerBound.description == "2026-10-01")
        #expect(earlier.lowerBound.description == "2026-08-01")
        #expect(year.lowerBound.description == "2026-01-01")
        #expect(!model.canMoveForward)
    }

    @Test
    func movesBackToCurrentPeriod() async throws {
        let setup = try await RecordsModelTests.Setup()
        let model = ReviewModel(database: setup.database, today: setup.today)
        let isCurrentAtFirst = model.isCurrentPeriod

        model.move(by: -3)
        let isCurrentAfterMove = model.isCurrentPeriod

        model.moveToCurrent()

        #expect(isCurrentAtFirst)
        #expect(!isCurrentAfterMove)
        #expect(model.isCurrentPeriod)
        #expect(model.isMovingForward)
        #expect(model.period.range.lowerBound.description == "2026-10-01")
    }

    @Test
    func remembersSelection() async throws {
        let setup = try await RecordsModelTests.Setup()
        let model = ReviewModel(database: setup.database, today: setup.today)

        model.setScale(.week)
        model.setKind(.income)
        await model.saveSelection()
        let reopened = ReviewModel(database: setup.database, today: setup.today)
        await reopened.loadSelection()

        #expect(reopened.scale == .week)
        #expect(reopened.kind == .income)
    }

    @Test
    func listsDaysOfStamp() async throws {
        let setup = try await RecordsModelTests.Setup()
        try setup.database.insertShelfIfEmpty(at: Date())
        let shelf = try await setup.database.shelfIconList().shelfIcons
        let star = try #require(shelf.first?.iconId)
        let party = try #require(shelf.dropFirst().first?.iconId)

        let stamps = [
            (star, "2026-10-05"),
            (party, "2026-10-10"),
            (star, "2026-10-12"),
            (star, "2026-09-20")
        ]

        for (icon, text) in stamps {
            let date = try #require(LocalDate(text))
            try await setup.database.stamp(icon, on: date, at: Date())
        }

        let model = ReviewModel(database: setup.database, today: setup.today)

        try await observe(model) {
            !model.stampTallies.isEmpty
        }

        let tally = try #require(model.stampTallies.first)
        let days = model.stampDays(of: tally).map(\.description)

        #expect(tally.count == 2)
        #expect(days == ["2026-10-12", "2026-10-05"])
    }
}
