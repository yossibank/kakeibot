import Core
import FeatureModels
import Foundation
import Store
import Testing
import TestSupport

extension ScreenFlowTests {
    @Test
    func nextDayTurnsTodayIntoYesterdayInEveryTab() async throws {
        let setup = try await Setup()
        let tomorrow = setup.today.adding(days: 1)
        let tabs = await setup.openTabs()
        _ = try await setup.record(1200)
        await tabs.wait { $0.amounts.allSatisfy { $0 == [1200] } }

        #expect(tabs.home.output.todayExpense == 1200)
        #expect(tabs.home.output.recentRows.first?.detail?.contains("今日") == true)

        try await setup.passDay(to: tomorrow, in: tabs)
        await tabs.wait { $0.assets.output.today == tomorrow }
        tabs.close()

        #expect(tabs.home.output.todayExpense == 0)
        #expect(tabs.home.output.yesterdayExpense == 1200)
        #expect(tabs.home.output.recentRows.first?.detail?.contains("昨日") == true)
        #expect(tabs.records.output.shownDate == tomorrow)
        #expect(tabs.review.output.total == 1200)
        #expect(tabs.assets.output.total == -1200)
    }

    @Test
    func plannedEntryCountsInBalancesWhenItsDayComes() async throws {
        let setup = try await Setup()
        let tomorrow = setup.today.adding(days: 1)
        let tabs = await setup.openTabs()
        _ = try await setup.record(5000, type: .income, on: tomorrow, wallet: setup.bank)
        await tabs.wait { $0.amounts.allSatisfy { $0 == [5000] } }

        #expect(tabs.assets.output.total == 0)
        #expect(tabs.assets.output.plans.map(\.change) == [5000])
        #expect(tabs.home.output.monthIncome == 5000)

        try await setup.passDay(to: tomorrow, in: tabs)
        await tabs.wait { $0.assets.output.today == tomorrow }
        tabs.close()

        #expect(tabs.assets.output.total == 5000)
        #expect(tabs.balance(of: setup.bank) == 5000)
        #expect(tabs.assets.output.plans.isEmpty)
        #expect(tabs.home.output.recentRows.first?.detail?.contains("今日") == true)
    }

    @Test
    func firstDayOfNextMonthStartsANewPeriodInEveryTab() async throws {
        let setup = try await Setup(today: "2026-10-31")
        let nextMonth = try #require(LocalDate("2026-11-01"))
        let tabs = await setup.openTabs()
        _ = try await setup.record(1200)
        await tabs.wait { $0.amounts.allSatisfy { $0 == [1200] } }

        #expect(tabs.home.output.monthExpense == 1200)
        #expect(tabs.assets.output.changeFromLastMonth == -1200)

        try await setup.passDay(to: nextMonth, in: tabs)
        await tabs.wait { $0.assets.output.today == nextMonth }

        #expect(tabs.home.output.month == nextMonth.yearMonth)
        #expect(tabs.home.output.monthExpense == 0)
        #expect(tabs.home.output.yesterdayExpense == 1200)
        #expect(tabs.records.output.currentMonth == nextMonth.yearMonth)
        #expect(tabs.review.output.period.range.lowerBound == nextMonth)
        #expect(tabs.review.output.total == 0)
        #expect(tabs.assets.output.currentMonth == nextMonth.yearMonth)
        #expect(tabs.assets.output.changeFromLastMonth == 0)
        #expect(tabs.assets.output.total == -1200)

        tabs.records.openCurrentMonth()
        tabs.review.move(by: -1)
        tabs.close()

        #expect(tabs.records.output.days.isEmpty)
        #expect(tabs.review.output.total == 1200)
    }

    @Test
    func entryRecordedAfterTheDayChangedLandsOnTheNewDay() async throws {
        let setup = try await Setup()
        let tomorrow = setup.today.adding(days: 1)
        let later = try await ScreenFlowTests.Setup(sharing: setup.database, today: tomorrow)
        let tabs = await setup.openTabs()
        _ = try await setup.record(1200)
        try await setup.passDay(to: tomorrow, in: tabs)

        let recorded = try await later.record(300)
        await tabs
            .wait { $0.amounts.allSatisfy { $0.count == 2 } && $0.assets.output.today == tomorrow }
        tabs.close()

        #expect(recorded.entry.date == tomorrow)
        #expect(tabs.home.output.todayExpense == 300)
        #expect(tabs.home.output.yesterdayExpense == 1200)
        #expect(tabs.records.output.days.map(\.date) == [tomorrow, setup.today])
        #expect(tabs.assets.output.total == -1500)
    }
}
