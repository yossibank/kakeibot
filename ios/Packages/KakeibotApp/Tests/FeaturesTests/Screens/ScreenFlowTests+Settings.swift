import Core
import FeatureModels
import Foundation
import Store
import Testing
import TestSupport

extension ScreenFlowTests {
    @Test
    func changedMonthStartDayMovesThePeriodOfEveryTab() async throws {
        let setup = try await Setup()
        let early = try #require(LocalDate("2026-10-05"))
        let late = try #require(LocalDate("2026-10-12"))
        let start = try #require(LocalDate("2026-10-10"))
        let startDay = try #require(MonthStartDay(10))
        let tabs = await setup.openTabs()
        _ = try await setup.record(500, on: early)
        _ = try await setup.record(1200, on: late)
        await tabs.wait { $0.amounts.allSatisfy { $0.count == 2 } }
        let settings = MonthStartDayModel(parts: .system(setup.database), today: setup.today)
        await settings.load()

        #expect(tabs.home.output.monthExpense == 1700)
        #expect(tabs.records.output.expenseTotal == 1700)
        #expect(tabs.review.output.total == 1700)

        await settings.choose(startDay)

        await tabs.wait {
            $0.home.output.monthStartDay == startDay
                && $0.records.input.monthStartDay == startDay
                && $0.review.input.monthStartDay == startDay
                && $0.assets.output.monthStartDay == startDay
        }

        #expect(tabs.home.output.period.lowerBound == start)
        #expect(tabs.home.output.monthExpense == 1200)
        #expect(tabs.records.output.period.lowerBound == start)
        #expect(tabs.records.output.isCurrentMonth)
        #expect(tabs.records.output.days.map(\.date) == [late])
        #expect(tabs.records.output.expenseTotal == 1200)
        #expect(tabs.review.output.period.range.lowerBound == start)
        #expect(tabs.review.output.total == 1200)
        #expect(tabs.assets.output.currentMonth == tabs.home.output.month)

        tabs.records.state.move(months: -1)
        tabs.review.move(by: -1)
        tabs.close()

        #expect(tabs.records.output.days.map(\.date) == [early])
        #expect(tabs.review.output.total == 500)
    }

    @Test
    func changedWeekStartMovesTheWeekOfRecordsAndReview() async throws {
        let setup = try await Setup()
        let sunday = try #require(LocalDate("2026-10-11"))
        let tabs = await setup.openTabs()
        _ = try await setup.record(700, on: sunday)
        await tabs.wait { $0.amounts.allSatisfy { $0 == [700] } }
        tabs.review.setScale(.week)
        let settings = SettingsMenuValueModel(parts: .system(setup.database), key: .weekStart)
        await settings.load()

        #expect(tabs.review.output.total == 700)
        #expect(tabs.records.output.weeks.first?.compactMap(\.self).count == 3)

        await settings.choose(.monday)
        await tabs
            .wait { $0.records.input.weekStart == .monday && $0.review.input.weekStart == .monday }
        tabs.close()

        #expect(tabs.review.output.period.range.lowerBound == sunday.adding(days: 1))
        #expect(tabs.review.output.total == 0)
        #expect(tabs.records.output.weeks.first?.compactMap(\.self).count == 4)
    }

    @Test
    func budgetSetInSettingsFollowsNewEntriesOnHome() async throws {
        let setup = try await Setup()
        let tabs = await setup.openTabs()
        _ = try await setup.record(1200)
        let settings = BudgetListModel(parts: .system(setup.database), today: setup.today)
        await settings.load()
        settings.startEditing(.total)

        for key in AmountCalculator.Key.digits(of: 30000) {
            settings.state.press(key)
        }

        await settings.save()
        await tabs.wait { $0.home.output.budgetUsage != nil && $0.review.input.budgets.count == 1 }

        #expect(tabs.home.output.budgetUsage?.remaining == 28800)
        #expect(tabs.home.output.middleTitle == "今月の支出")

        _ = try await setup.record(800)
        await tabs.wait { $0.home.output.budgetUsage?.remaining == 28000 }

        settings.startEditing(.total)
        let cleared = try #require(await settings.clear())
        await tabs.wait { $0.home.output.budgetUsage == nil && $0.review.input.budgets.isEmpty }

        #expect(tabs.home.output.middleTitle == "昨日の支出")

        await settings.restore(cleared)
        await tabs.wait { $0.home.output.budgetUsage != nil && $0.review.input.budgets.count == 1 }
        tabs.close()

        #expect(tabs.home.output.budgetUsage?.remaining == 28000)
    }

    @Test
    func hiddenWalletLeavesAssetsAndEntryChoicesButKeepsItsRecords() async throws {
        let setup = try await Setup()
        let tabs = await setup.openTabs()
        let recorded = try await setup.record(5000, type: .income, wallet: setup.bank)
        await tabs.wait { $0.balance(of: setup.bank) == 5000 }
        let draft = await setup.entryModel()
        draft.setWallet(setup.bank)
        let settings = WalletEditModel(
            parts: ScreenParts(database: setup.database, clock: setup.clock),
            editing: setup.bank
        )
        await settings.load()

        let isHidden = await settings.setHidden(true)
        await tabs.wait { $0.balance(of: setup.bank) == nil }
        await draft.reloadWallets()

        #expect(isHidden)
        #expect(tabs.assets.output.rows.map(\.wallet.id) == [setup.cash])
        #expect(tabs.entryIDs.allSatisfy { $0 == [recorded.entry.id] })
        #expect(tabs.records.output.incomeTotal == 5000)
        #expect(tabs.home.output.monthIncome == 5000)
        #expect(tabs.review.output.total(of: .income) == 5000)
        #expect(draft.output.wallets.map(\.id) == [setup.cash])
        #expect(draft.state.payment.walletId == setup.cash)

        let isShown = await settings.setHidden(false)
        await tabs.wait { $0.balance(of: setup.bank) == 5000 }
        await draft.reloadWallets()
        tabs.close()

        #expect(isShown)
        #expect(tabs.assets.output.total == 5000)
        #expect(draft.output.wallets.map(\.id) == [setup.cash, setup.bank])
    }

    @Test
    func hiddenCategoryKeepsNamingRecordsButLeavesEntryChoices() async throws {
        let setup = try await Setup()
        let tabs = await setup.openTabs()
        let recorded = try await setup.record(1200)
        let categoryID = try #require(recorded.entry.categoryId)
        await tabs.wait { $0.amounts.allSatisfy { $0 == [1200] } }
        let title = try #require(tabs.home.output.recentRows.first?.title)
        let draft = await setup.entryModel()

        let settings = CategoryEditModel(
            parts: ScreenParts(database: setup.database, clock: setup.clock),
            kind: .expense,
            editing: categoryID
        )

        await settings.load()

        try await settings.saveHidden(categoryID, isHidden: true)
        await tabs.wait { $0.lists.allSatisfy { $0?.categories[categoryID]?.archivedAt != nil } }
        await draft.reloadCategories()
        tabs.close()

        let day = try #require(tabs.records.output.days.first)

        #expect(draft.state.category.id != categoryID)
        #expect(!draft.output.categories.map(\.id).contains(categoryID))
        #expect(tabs.home.output.recentRows.map(\.title) == [title])
        #expect(tabs.records.output.rows(for: day).map(\.title) == [title])
        #expect(tabs.review.output.total == 1200)
    }
}
