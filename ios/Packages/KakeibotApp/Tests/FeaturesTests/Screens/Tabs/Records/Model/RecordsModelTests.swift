import Core
import FeatureModels
import Features
import Foundation
import Store
import Testing
import TestSupport

@MainActor
struct RecordsModelTests {
    @Test
    func showsNoRecordsOnlyAfterListArrives() async throws {
        let setup = try await HomeModelTests.Setup()
        let model = RecordsModel(parts: .system(setup.database), today: setup.today)
        let before = model.output.showsNoRecords

        await model.load()

        #expect(before == false)
        #expect(model.output.showsNoRecords)
    }

    @Test
    func showsOnlyDaysInMonth() async throws {
        let setup = try await Setup()
        try await setup.save(.expense, amount: 980, on: "2026-10-12")
        try await setup.save(.income, amount: 250_000, on: "2026-10-10")
        try await setup.save(.expense, amount: 3980, on: "2026-10-10")
        try await setup.save(.expense, amount: 500, on: "2026-09-30")
        let model = RecordsModel(parts: .system(setup.database), today: setup.today)

        await model.load()
        let dates = model.output.days.map(\.date.description)

        #expect(dates == ["2026-10-12", "2026-10-10"])
        #expect(model.output.expenseTotal == 4960)
        #expect(model.output.incomeTotal == 250_000)

        model.state.move(months: -1)

        #expect(model.state.month.description == "2026-09")
        #expect(model.output.days.map(\.date.description) == ["2026-09-30"])
        #expect(model.output.expenseTotal == 500)
    }

    @Test
    func keepsMonthWhenObservingAgain() async throws {
        let setup = try await Setup()
        let model = RecordsModel(parts: .system(setup.database), today: setup.today)

        let first = Task {
            await model.run()
        }

        await ObservationWait.until {
            model.input.list != nil
        }

        first.cancel()
        await first.value
        model.state.move(months: -1)
        try await setup.save(.expense, amount: 500, on: "2026-09-30")

        let second = Task {
            await model.run()
        }

        await ObservationWait.until {
            model.output.days.count == 1
        }

        try await setup.database.setSetting(.weekStart, to: .monday)

        await ObservationWait.until {
            model.input.weekStart == .monday
        }

        second.cancel()

        #expect(model.state.month.description == "2026-09")
    }

    @Test
    func showsUpcomingRecurringOnFutureDays() async throws {
        let setup = try await Setup()
        let options = try await setup.database.entryOptions()
        let start = try #require(LocalDate("2026-09-01"))
        let past = try #require(LocalDate("2026-09-27"))
        let future = try #require(LocalDate("2026-10-27"))

        let draft = RecurringDraft(
            type: .expense,
            amount: 78000,
            categoryId: options.expenseCategories.first?.id,
            walletId: options.wallets.first?.id,
            memo: "家賃",
            frequency: .monthly,
            month: 1,
            day: 27,
            startDate: start
        )

        _ = try await setup.database.saveRecurring(draft, today: setup.today, at: Date())
        let model = RecordsModel(parts: .system(setup.database), today: setup.today)

        await model.load()
        let upcoming = model.output.upcomingRecurrings(on: future)

        #expect(upcoming.map(model.output.title) == ["家賃"])
        #expect(model.output.upcomingRecurrings(on: past).isEmpty)
    }

    @Test
    func listsUpcomingDaysAmongRecordedDays() async throws {
        let setup = try await Setup()
        let options = try await setup.database.entryOptions()
        let start = try #require(LocalDate("2026-09-01"))

        let draft = RecurringDraft(
            type: .expense,
            amount: 78000,
            categoryId: options.expenseCategories.first?.id,
            walletId: options.wallets.first?.id,
            memo: "家賃",
            frequency: .monthly,
            month: 1,
            day: 27,
            startDate: start
        )

        _ = try await setup.database.saveRecurring(draft, today: setup.today, at: Date())
        try await setup.save(.expense, amount: 980, on: "2026-10-12", memo: "ランチ")
        let model = RecordsModel(parts: .system(setup.database), today: setup.today)

        await model.load()

        #expect(model.output.upcomingDates.map(\.description) == ["2026-10-27"])
        #expect(model.output.listDays.map(\.date.description) == ["2026-10-27", "2026-10-12"])
        #expect(model.output.listDays.first?.day == nil)
        let captions = model.output.listCaptions(in: model.output.listDays)

        #expect(model.output.listDays.map { captions[$0.date] } == ["これから", "これまで"])
    }

    @Test
    func hidesUpcomingRecurringsWhileSearching() async throws {
        let setup = try await Setup()
        let options = try await setup.database.entryOptions()
        let start = try #require(LocalDate("2026-09-01"))
        let day = try #require(LocalDate("2026-10-27"))

        let draft = RecurringDraft(
            type: .expense,
            amount: 78000,
            categoryId: options.expenseCategories.first?.id,
            walletId: options.wallets.first?.id,
            memo: "家賃",
            frequency: .monthly,
            month: 1,
            day: 27,
            startDate: start
        )

        _ = try await setup.database.saveRecurring(draft, today: setup.today, at: Date())
        let model = RecordsModel(parts: .system(setup.database), today: setup.today)

        await model.load()

        #expect(model.output.listRecurrings(on: day).count == 1)

        model.state.isSearching = true

        #expect(model.output.listRecurrings(on: day).isEmpty)
    }

    @Test
    func describesRowsWithMemoAndWallet() async throws {
        let setup = try await Setup()
        try await setup.save(.expense, amount: 980, on: "2026-10-12", memo: "ランチ")
        try await setup.save(.expense, amount: 220, on: "2026-10-12", memo: "")
        let model = RecordsModel(parts: .system(setup.database), today: setup.today)

        await model.load()
        let day = try #require(model.output.days.first)
        let rows = model.output.rows(for: day)

        #expect(rows.map(\.detail) == ["財布", "財布"])
        #expect(rows.map(\.memo) == [nil, "ランチ"])
        #expect(rows.map(\.type) == [.expense, .expense])
    }

    @Test
    func describesFeeRowWithTransferRoute() async throws {
        let setup = try await Setup()
        let options = try await setup.database.entryOptions()
        let date = try #require(LocalDate("2026-10-12"))

        let draft = EntryDraft(
            type: .transfer,
            amount: 10000,
            date: date,
            categoryId: nil,
            walletId: options.wallets[1].id,
            toWalletId: options.wallets[0].id,
            fee: 110
        )

        try await setup.database.saveEntry(draft, at: Date())
        let model = RecordsModel(parts: .system(setup.database), today: setup.today)

        await model.load()
        let day = try #require(model.output.days.first)

        let routes = model.output.rows(for: day)
            .compactMap(\.route)
            .map { "\($0.source) → \($0.destination)" }

        #expect(routes.contains("銀行 → 財布 の手数料"))
        #expect(routes.contains("銀行 → 財布"))
    }

    @Test
    func showsTodayUntilAnotherDayIsChosen() async throws {
        let setup = try await Setup()
        let model = RecordsModel(parts: .system(setup.database), today: setup.today)
        let chosen = try #require(LocalDate("2026-10-03"))

        let initial = model.output.shownDate
        model.state.selectedDate = chosen
        let selected = model.output.shownDate
        model.state.move(months: -1)
        let moved = model.output.shownDate

        #expect(initial == setup.today)
        #expect(selected == chosen)
        #expect(moved.description == "2026-09-01")
    }

    @Test
    func marksOnlyPastDaysWithoutExpense() async throws {
        let setup = try await Setup()
        try await setup.save(.expense, amount: 980, on: "2026-10-12")
        try await setup.save(.income, amount: 3000, on: "2026-10-10")
        let model = RecordsModel(parts: .system(setup.database), today: setup.today)
        let spent = try #require(LocalDate("2026-10-12"))
        let income = try #require(LocalDate("2026-10-10"))
        let future = setup.today.adding(days: 1)

        await model.load()

        #expect(!model.output.canMarkNoSpend(on: spent))
        #expect(model.output.canMarkNoSpend(on: income))
        #expect(model.output.canMarkNoSpend(on: setup.today))
        #expect(!model.output.canMarkNoSpend(on: future))
    }
}
