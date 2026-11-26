import Core
import FeatureModels
import Features
import Foundation
import Store
import Testing

@MainActor
struct AssetsAdjustmentModelTests {
    @Test
    func asksToAdjustOnlyNegativeOnHandWallets() async throws {
        let setup = try await AssetsModelTests.Setup()
        try await setup.save(.expense, 37580, on: "2026-10-10", from: setup.cash)
        try await setup.save(.income, 1000, on: "2026-10-10", from: setup.bank)
        let model = AssetsModel(parts: .system(setup.database), today: setup.today)

        await model.load()
        let flags = model.output.rows.map(\.needsAdjustment)

        #expect(flags == [true, false])
    }

    @Test
    func adjustsBalanceToEnteredAmountWithoutSpending() async throws {
        let setup = try await AssetsModelTests.Setup()
        try await setup.save(.expense, 37580, on: "2026-10-10", from: setup.cash)
        let model = AssetsModel(parts: .system(setup.database), today: setup.today)
        await model.load()
        let row = try #require(model.output.rows.first)
        let adjust = model.adjustModel(for: row)

        for key in [AmountCalculator.Key.digit(1), .digit(2), .digit(0)] {
            adjust.state.press(key)
        }

        await adjust.flow.save().value
        await model.load()
        let list = try await setup.database.entryList()

        #expect(adjust.output.difference == 37700)
        #expect(adjust.flow.state.outcome.value?.closes == true)
        #expect(model.output.rows.first?.balance == 120)
        #expect(model.output.rows.first?.needsAdjustment == false)
        #expect(list.adjustments.map(\.date) == [setup.today])
        #expect(list.days.map(\.expenseTotal) == [37580])
    }

    @Test
    func refusesToSaveWithoutDifference() async throws {
        let setup = try await AssetsModelTests.Setup()
        let model = AssetsModel(parts: .system(setup.database), today: setup.today)
        await model.load()
        let row = try #require(model.output.rows.first)
        let adjust = model.adjustModel(for: row)

        await adjust.flow.save().value
        let list = try await setup.database.entryList()

        #expect(!adjust.flow.output.canSave)
        #expect(adjust.flow.state.outcome.value == nil)
        #expect(list.adjustments.isEmpty)
    }

    @Test
    func reportsChangeOnlyWhileAmountDiffersFromOpening() async throws {
        let setup = try await AssetsModelTests.Setup()
        let model = AssetsModel(parts: .system(setup.database), today: setup.today)
        await model.load()
        let row = try #require(model.output.rows.first)
        let adjust = model.adjustModel(for: row)

        let opened = adjust.flow.output.isChanged
        adjust.state.press(.digit(5))
        let typed = adjust.flow.output.isChanged
        adjust.state.press(.delete)

        #expect(!opened)
        #expect(typed)
        #expect(!adjust.flow.output.isChanged)
    }

    @Test
    func describesDifference() async throws {
        let setup = try await AssetsModelTests.Setup()
        try await setup.save(.expense, 37580, on: "2026-10-10", from: setup.cash)
        let model = AssetsModel(parts: .system(setup.database), today: setup.today)
        await model.load()
        let row = try #require(model.output.rows.first)
        let adjust = model.adjustModel(for: row)

        #expect(adjust.output.differenceText == "+¥37,580")
        #expect(adjust.output.differenceNote == "差は今日の記録に入ります")
        #expect(adjust.output.saveTitle == "+¥37,580 で合わせる")
    }
}
