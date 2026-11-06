import Core
import Features
import Foundation
import Store
import Testing

@MainActor
struct AssetsAdjustModelTests {
    @Test
    func asksToAdjustOnlyNegativeOnHandWallets() async throws {
        let setup = try await AssetsModelTests.Setup()
        try await setup.save(.expense, 37580, on: "2026-10-10", from: setup.cash)
        try await setup.save(.income, 1000, on: "2026-10-10", from: setup.bank)
        let model = AssetsModel(database: setup.database, today: setup.today)

        await model.load()
        let flags = model.rows.map(\.needsAdjustment)

        #expect(flags == [true, false])
    }

    @Test
    func adjustsBalanceToEnteredAmountWithoutSpending() async throws {
        let setup = try await AssetsModelTests.Setup()
        try await setup.save(.expense, 37580, on: "2026-10-10", from: setup.cash)
        let model = AssetsModel(database: setup.database, today: setup.today)
        await model.load()
        let row = try #require(model.rows.first)
        let adjust = model.adjustModel(for: row)

        for key in [AmountCalculator.Key.digit(1), .digit(2), .digit(0)] {
            adjust.press(key)
        }

        let saved = await adjust.save()
        await model.load()
        let list = try await setup.database.entryList()

        #expect(adjust.difference == 37700)
        #expect(saved)
        #expect(model.rows.first?.balance == 120)
        #expect(model.rows.first?.needsAdjustment == false)
        #expect(list.adjustments.map(\.date) == [setup.today])
        #expect(list.days.map(\.expenseTotal) == [37580])
    }

    @Test
    func refusesToSaveWithoutDifference() async throws {
        let setup = try await AssetsModelTests.Setup()
        let model = AssetsModel(database: setup.database, today: setup.today)
        await model.load()
        let row = try #require(model.rows.first)
        let adjust = model.adjustModel(for: row)

        let saved = await adjust.save()
        let list = try await setup.database.entryList()

        #expect(!adjust.canSave)
        #expect(!saved)
        #expect(list.adjustments.isEmpty)
    }

    @Test
    func reportsChangeOnlyWhileAmountDiffersFromOpening() async throws {
        let setup = try await AssetsModelTests.Setup()
        let model = AssetsModel(database: setup.database, today: setup.today)
        await model.load()
        let row = try #require(model.rows.first)
        let adjust = model.adjustModel(for: row)

        let opened = adjust.isChanged
        adjust.press(.digit(5))
        let typed = adjust.isChanged
        adjust.press(.delete)

        #expect(!opened)
        #expect(typed)
        #expect(!adjust.isChanged)
    }

    @Test
    func describesDifference() async throws {
        let setup = try await AssetsModelTests.Setup()
        try await setup.save(.expense, 37580, on: "2026-10-10", from: setup.cash)
        let model = AssetsModel(database: setup.database, today: setup.today)
        await model.load()
        let row = try #require(model.rows.first)
        let adjust = model.adjustModel(for: row)

        #expect(adjust.differenceText == "+¥37,580")
        #expect(adjust.differenceNote == "差は今日の記録に入ります")
        #expect(adjust.saveTitle == "+¥37,580 で合わせる")
    }
}
