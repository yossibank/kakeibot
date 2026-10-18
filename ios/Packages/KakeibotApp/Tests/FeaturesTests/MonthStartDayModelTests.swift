import Core
import Features
import Foundation
import Store
import Testing

@MainActor
struct MonthStartDayModelTests {
    @Test
    func choosesAndSavesStartDay() async throws {
        let setup = try await HomeModelTests.Setup()
        let payday = try #require(MonthStartDay(25))

        let model = MonthStartDayModel(
            database: setup.database,
            today: setup.today
        )

        await model.load()
        let initial = model.periodText
        await model.choose(payday)
        let saved = try await setup.database.monthStartDay()

        #expect(initial == "10/1〜10/31")
        #expect(model.periodText == "9/25〜10/24")
        #expect(model.month == YearMonth(year: 2026, month: 10))
        #expect(saved == payday)
    }

    @Test
    func countsHomeByPeriod() async throws {
        let setup = try await HomeModelTests.Setup()
        try await setup.save(.expense, amount: 980, daysAgo: 0)
        try await setup.save(.expense, amount: 500, daysAgo: 17)
        try await setup.save(.expense, amount: 3000, daysAgo: 18)
        let startDay = try #require(MonthStartDay(25))
        try await setup.database.setMonthStartDay(startDay)
        let model = HomeModel(database: setup.database, today: setup.today)

        let task = Task {
            await model.run()
        }

        try await wait {
            model.monthStartDay == startDay && model.list != nil
        }

        task.cancel()

        #expect(model.monthExpense == 1480)
        #expect(model.monthRangeText == "9/25〜10/24")
    }

    @Test
    func opensRecordsAtTodaysPeriod() async throws {
        let setup = try await HomeModelTests.Setup()
        try await setup.save(.expense, amount: 500, daysAgo: 17)
        try await setup.save(.expense, amount: 3000, daysAgo: 18)
        let startDay = try #require(MonthStartDay(10))
        try await setup.database.setMonthStartDay(startDay)
        let model = RecordsModel(database: setup.database, today: setup.today)

        let task = Task {
            await model.run()
        }

        try await wait {
            model.monthStartDay == startDay && model.list != nil
        }

        task.cancel()

        #expect(model.month == YearMonth(year: 2026, month: 11))
        #expect(model.periodText == "10/10〜11/9")
        #expect(model.expenseTotal == 0)

        model.move(months: -1)

        #expect(model.periodText == "9/10〜10/9")
        #expect(model.expenseTotal == 3500)
    }

    @Test
    func endsAssetMonthsAtPeriodEnd() async throws {
        let setup = try await HomeModelTests.Setup()
        let startDay = try #require(MonthStartDay(10))
        try await setup.database.setMonthStartDay(startDay)
        let model = AssetsModel(database: setup.database, today: setup.today)

        let task = Task {
            await model.run()
        }

        try await wait {
            model.monthStartDay == startDay && model.list != nil
        }

        task.cancel()

        #expect(model.currentMonth == YearMonth(year: 2026, month: 11))
        #expect(model.monthTotals.last?.month == model.currentMonth)
    }
}

private extension MonthStartDayModelTests {
    func wait(until isReady: () -> Bool) async throws {
        for _ in 0..<200 where !isReady() {
            try await Task.sleep(for: .milliseconds(10))
        }
    }
}
