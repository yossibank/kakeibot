import Core
import FeatureModels
import Foundation
import Store
import Testing
import TestSupport

extension ScreenFlowTests {
    @Test
    func transferWithFeeMovesBalancesUntilDeletedAndUndone() async throws {
        let setup = try await Setup()
        let tabs = await setup.openTabs()
        let entry = await setup.entryModel(type: .transfer)
        entry.type(10000)
        entry.state.setFee(220)

        let recorded = try #require(await entry.save())
        await tabs.wait { $0.amounts.allSatisfy { $0.count == 2 } }

        #expect(recorded.fee?.amount == 220)
        #expect(tabs.balance(of: setup.cash) == -10220)
        #expect(tabs.balance(of: setup.bank) == 10000)
        #expect(tabs.assets.output.total == -220)
        #expect(tabs.home.output.monthExpense == 220)
        #expect(tabs.records.output.expenseTotal == 220)
        #expect(tabs.review.output.total == 220)

        await tabs.notice.delete(recorded.entry.id, in: tabs.records.input.list.value)
        await tabs.wait { $0.amounts.allSatisfy(\.isEmpty) }

        #expect(tabs.balance(of: setup.cash) == 0)
        #expect(tabs.balance(of: setup.bank) == 0)
        #expect(tabs.home.output.monthExpense == 0)

        await tabs.notice.undo()
        await tabs.wait { $0.amounts.allSatisfy { $0.count == 2 } }
        tabs.close()

        #expect(tabs.balance(of: setup.cash) == -10220)
        #expect(tabs.balance(of: setup.bank) == 10000)
        #expect(tabs.home.output.monthExpense == 220)
        #expect(tabs.records.output.expenseTotal == 220)
        #expect(tabs.review.output.total == 220)
    }

    @Test
    func cardExpenseWaitsForItsBillAndIsPaidWhenTheDayComes() async throws {
        let setup = try await Setup()
        let card = try await setup.saveCard()
        let payDay = try #require(LocalDate("2026-11-27"))
        let tabs = await setup.openTabs()
        let entry = await setup.entryModel()
        entry.type(3000)
        entry.setWallet(card.id)

        _ = try #require(await entry.save())
        await tabs.wait { $0.balance(of: card.id) == -3000 }

        #expect(tabs.balance(of: setup.bank) == 0)
        #expect(tabs.assets.output.holdings.onHand == 0)
        #expect(tabs.assets.output.total == -3000)
        #expect(tabs.assets.output.upcomingBills.map(\.bill.amount) == [3000])
        #expect(tabs.assets.output.upcomingBills.map(\.bill.date) == [payDay])
        #expect(tabs.home.output.billPages.map(\.total) == [3000])
        #expect(tabs.home.output.monthExpense == 3000)

        try await setup.passDay(to: payDay, in: tabs)
        await tabs.wait { $0.assets.output.today == payDay && $0.balance(of: card.id) == 0 }
        tabs.records.openCurrentMonth()
        tabs.close()

        let day = try #require(tabs.records.output.days.first)
        let rows = tabs.records.output.rows(for: day)

        #expect(tabs.balance(of: setup.bank) == -3000)
        #expect(tabs.assets.output.holdings.onHand == -3000)
        #expect(tabs.assets.output.total == -3000)
        #expect(day.date == payDay)
        #expect(rows.map(\.type) == [.transfer])
        #expect(rows.map(\.amount) == [3000])
        #expect(tabs.home.output.monthExpense == 0)
    }

    @Test
    func recurringSavedInSettingsFillsTabsAndIsRecordedOnItsNextDay() async throws {
        let setup = try await Setup()
        let start = try #require(LocalDate("2026-09-01"))
        let nextDay = try #require(LocalDate("2026-11-10"))
        let tabs = await setup.openTabs()
        let editor = RecurringEditModel(
            parts: ScreenParts(database: setup.database, clock: setup.clock),
            today: setup.today
        )
        await editor.load()

        for key in AmountCalculator.Key.digits(of: 78000) {
            editor.state.press(key)
        }

        editor.state.fields.memo = "家賃"
        editor.state.fields.schedule.day = 10
        editor.state.fields.schedule.startDate = start
        let isSaved = await editor.save() != nil
        await tabs.wait {
            $0.amounts.allSatisfy { $0 == [78000, 78000] }
                && $0.home.output.periodRecurrings.map(\.status) == [.done]
        }

        #expect(isSaved)
        #expect(tabs.home.output.periodRecurrings.map(\.status) == [.done])
        #expect(tabs.home.output.paidRecurringExpense == 78000)
        #expect(tabs.records.output.days.map(\.date.description) == ["2026-10-10"])
        #expect(tabs.review.output.total == 78000)
        #expect(tabs.balance(of: setup.cash) == -156_000)

        let paid = try #require(tabs.home.output.periodRecurrings.first?.entry)
        await tabs.notice.delete(paid.id, in: tabs.records.input.list.value)
        await tabs.wait { $0.home.output.periodRecurrings.map(\.status) == [.missing] }
        await tabs.wait { $0.balance(of: setup.cash) == -78000 }

        #expect(tabs.records.output.days.isEmpty)
        #expect(tabs.home.output.paidRecurringExpense == 0)

        let missing = try #require(tabs.home.output.periodRecurrings.first)
        await tabs.home.record(missing)
        await tabs.wait { $0.balance(of: setup.cash) == -156_000 }

        #expect(tabs.home.output.periodRecurrings.map(\.status) == [.done])
        #expect(tabs.records.output.days.map(\.date.description) == ["2026-10-10"])

        try await setup.passDay(to: nextDay, in: tabs)
        await tabs
            .wait { $0.assets.output.today == nextDay && $0.balance(of: setup.cash) == -234_000 }
        tabs.records.openCurrentMonth()
        tabs.close()

        #expect(tabs.home.output.periodRecurrings.map(\.status) == [.done])
        #expect(tabs.home.output.periodRecurrings.map(\.date) == [nextDay])
        #expect(tabs.records.output.days.map(\.date) == [nextDay])
        #expect(tabs.review.output.total == 78000)
    }
}
