import Core
import FeatureModels
import Features
import Foundation
import Store
import Testing
import TestSupport

@MainActor
struct MonthStartDayModelTests {
    @Test
    func choosesAndSavesStartDay() async throws {
        let setup = try await HomeModelTests.Setup()
        let payday = try #require(MonthStartDay(25))
        let model = MonthStartDayModel(database: setup.database, today: setup.today)

        await model.load()
        let initial = model.output.periodText
        await model.choose(payday)
        let saved = try await setup.database.setting(.monthStartDay)

        #expect(initial == "10/1〜10/31")
        #expect(model.output.periodText == "9/25〜10/24")
        #expect(model.output.month == YearMonth(year: 2026, month: 10))
        #expect(saved == payday)
    }

    @Test
    func keepsShiftWhenChangingDay() async throws {
        let setup = try await HomeModelTests.Setup()
        let payday = try #require(MonthStartDay(25))
        let earlier = try #require(MonthStartDay(20))
        let model = MonthStartDayModel(database: setup.database, today: setup.today)

        await model.load()
        await model.choose(payday)
        let plainNote = model.output.shiftNote
        await model.choose(.previous)
        let shiftedText = model.output.periodText
        let weekdayNote = model.output.shiftNote
        await model.choose(earlier)
        let saved = try await setup.database.setting(.monthStartDay)

        #expect(plainNote == "土日・祝日でも、そのまま数えます")
        #expect(shiftedText == "9/25〜10/22")
        #expect(weekdayNote == "今の期間の始まりは、平日です")
        #expect(model.output.periodText == "9/18〜10/19")
        #expect(model.output.shiftNote == "9/20（日）を 9/18（金）にずらしています")
        #expect(saved == earlier.shifted(by: .previous))
    }

    @Test
    func countsHomeByPeriod() async throws {
        let setup = try await HomeModelTests.Setup()
        try await setup.save(.expense, amount: 980, daysAgo: 0)
        try await setup.save(.expense, amount: 500, daysAgo: 17)
        try await setup.save(.expense, amount: 3000, daysAgo: 18)
        let startDay = try #require(MonthStartDay(25))
        try await setup.database.setSetting(.monthStartDay, to: startDay)
        let model = HomeModel(database: setup.database, clock: .system, today: setup.today)

        let task = Task {
            await model.run()
        }

        try await wait {
            model.output.monthStartDay == startDay && model.input.list != nil
        }

        task.cancel()

        #expect(model.output.monthExpense == 1480)
        #expect(model.output.monthRangeText == "9/25〜10/24")
    }

    @Test
    func opensRecordsAtTodaysPeriod() async throws {
        let setup = try await HomeModelTests.Setup()
        try await setup.save(.expense, amount: 500, daysAgo: 17)
        try await setup.save(.expense, amount: 3000, daysAgo: 18)
        let startDay = try #require(MonthStartDay(10))
        try await setup.database.setSetting(.monthStartDay, to: startDay)
        let model = RecordsModel(database: setup.database, clock: .system, today: setup.today)

        let task = Task {
            await model.run()
        }

        try await wait {
            model.input.monthStartDay == startDay && model.input.list != nil
        }

        task.cancel()

        #expect(model.state.month == YearMonth(year: 2026, month: 11))
        #expect(model.output.periodText == "10/10〜11/9")
        #expect(model.output.expenseTotal == 0)

        model.state.move(months: -1)

        #expect(model.output.periodText == "9/10〜10/9")
        #expect(model.output.expenseTotal == 3500)
    }

    @Test
    func endsAssetMonthsAtPeriodEnd() async throws {
        let setup = try await HomeModelTests.Setup()
        let startDay = try #require(MonthStartDay(10))
        try await setup.database.setSetting(.monthStartDay, to: startDay)
        let model = AssetsModel(database: setup.database, clock: .system, today: setup.today)

        let task = Task {
            await model.run()
        }

        try await wait {
            model.output.monthStartDay == startDay && model.output.list != nil
        }

        task.cancel()

        #expect(model.output.currentMonth == YearMonth(year: 2026, month: 11))
        #expect(model.output.monthTotals.last?.month == model.output.currentMonth)
    }
}

private extension MonthStartDayModelTests {
    func wait(
        sourceLocation: SourceLocation = #_sourceLocation,
        until isReady: @escaping @MainActor () -> Bool
    ) async throws {
        await ObservationWait.until(
            sourceLocation: sourceLocation,
            isReady
        )
    }
}
