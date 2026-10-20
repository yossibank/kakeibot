import Core
import Features
import Foundation
import Store
import Testing

@MainActor
struct RecordsModelTests {
    @Test
    func showsOnlyDaysInMonth() async throws {
        let setup = try await Setup()
        try await setup.save(.expense, amount: 980, on: "2026-10-12")
        try await setup.save(.income, amount: 250_000, on: "2026-10-10")
        try await setup.save(.expense, amount: 3980, on: "2026-10-10")
        try await setup.save(.expense, amount: 500, on: "2026-09-30")
        let model = RecordsModel(database: setup.database, today: setup.today)

        await model.load()
        let dates = model.days.map(\.date.description)

        #expect(dates == ["2026-10-12", "2026-10-10"])
        #expect(model.expenseTotal == 4960)
        #expect(model.incomeTotal == 250_000)

        model.move(months: -1)

        #expect(model.month.description == "2026-09")
        #expect(model.days.map(\.date.description) == ["2026-09-30"])
        #expect(model.expenseTotal == 500)
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
        _ = try await setup.database.saveRecurring(
            draft,
            today: setup.today,
            at: Date()
        )
        let model = RecordsModel(database: setup.database, today: setup.today)

        await model.load()
        let upcoming = model.upcomingRecurrings(on: future)

        #expect(upcoming.map(model.title) == ["家賃"])
        #expect(model.upcomingRecurrings(on: past).isEmpty)
    }

    @Test
    func describesRowsWithMemoAndWallet() async throws {
        let setup = try await Setup()
        try await setup.save(
            .expense,
            amount: 980,
            on: "2026-10-12",
            memo: "ランチ"
        )
        try await setup.save(.expense, amount: 220, on: "2026-10-12", memo: "")
        let model = RecordsModel(database: setup.database, today: setup.today)

        await model.load()
        let day = try #require(model.days.first)
        let rows = model.rows(for: day)

        #expect(rows.map(\.detail) == ["財布", "ランチ・財布"])
        #expect(rows.map(\.type) == [.expense, .expense])
    }

    @Test
    func showsTodayUntilAnotherDayIsChosen() async throws {
        let setup = try await Setup()
        let model = RecordsModel(database: setup.database, today: setup.today)
        let chosen = try #require(LocalDate("2026-10-03"))

        let initial = model.shownDate
        model.selectedDate = chosen
        let selected = model.shownDate
        model.move(months: -1)
        let moved = model.shownDate

        #expect(initial == setup.today)
        #expect(selected == chosen)
        #expect(moved.description == "2026-09-01")
    }

    @Test
    func marksOnlyPastDaysWithoutExpense() async throws {
        let setup = try await Setup()
        try await setup.save(.expense, amount: 980, on: "2026-10-12")
        try await setup.save(.income, amount: 3000, on: "2026-10-10")
        let model = RecordsModel(database: setup.database, today: setup.today)
        let spent = try #require(LocalDate("2026-10-12"))
        let income = try #require(LocalDate("2026-10-10"))
        let future = setup.today.adding(days: 1)

        await model.load()

        #expect(!model.canMarkNoSpend(on: spent))
        #expect(model.canMarkNoSpend(on: income))
        #expect(model.canMarkNoSpend(on: setup.today))
        #expect(!model.canMarkNoSpend(on: future))
    }

    @Test
    func togglesNoSpendDay() async throws {
        let setup = try await Setup()
        let model = RecordsModel(database: setup.database, today: setup.today)

        let task = Task {
            await model.run()
        }

        await model.toggleNoSpendDay(on: setup.today)

        for _ in 0..<200 where model.noSpendDays.isEmpty {
            try await Task.sleep(for: .milliseconds(10))
        }

        let marked = model.noSpendDays
        await model.toggleNoSpendDay(on: setup.today)

        for _ in 0..<200 where !model.noSpendDays.isEmpty {
            try await Task.sleep(for: .milliseconds(10))
        }

        let unmarked = model.noSpendDays
        task.cancel()

        #expect(marked == [setup.today])
        #expect(unmarked.isEmpty)
    }

    @Test
    func remembersLayout() async throws {
        let setup = try await Setup()
        let model = RecordsModel(database: setup.database, today: setup.today)

        model.setLayout(.calendar)
        await model.saveLayout()
        let reopened = RecordsModel(
            database: setup.database,
            today: setup.today
        )
        await reopened.loadLayout()

        #expect(reopened.layout == .calendar)
    }

    @Test
    func opensDayInCalendar() async throws {
        let setup = try await Setup()
        let model = RecordsModel(database: setup.database, today: setup.today)
        let date = try #require(LocalDate("2026-08-03"))

        model.open(date)

        #expect(model.month.description == "2026-08")
        #expect(model.shownDate == date)
        #expect(model.layout == .calendar)
    }

    @Test
    func stampsAndRemovesWithShownChoices() async throws {
        let setup = try await Setup()
        try setup.database.insertShelfIfEmpty(at: Date())
        let shelf = try await setup.database.iconShelf()
        let hidden = try #require(shelf.shelfIcons.last)
        try await setup.database.setShelfIconHidden(
            hidden.id,
            isHidden: true,
            at: Date()
        )
        let today = setup.today
        let model = RecordsModel(database: setup.database, today: today)

        let task = Task {
            await model.run()
        }

        for _ in 0..<200 where model.stampChoices.isEmpty {
            try await Task.sleep(for: .milliseconds(10))
        }

        let choices = model.stampChoices
        let star = try #require(choices.first)
        let party = try #require(choices.dropFirst().first)

        await model.stamp(star, on: today)
        await model.stamp(party, on: today)

        for _ in 0..<200 where model.stampIcon(on: today)?.id != party.id {
            try await Task.sleep(for: .milliseconds(10))
        }

        let stamped = model.stampIcon(on: today)
        await model.removeStamp(on: today)
        let calendar = try await setup.database.stampCalendar()
        task.cancel()

        #expect(choices.count == 7)
        #expect(!choices.contains { $0.id == hidden.iconId })
        #expect(stamped?.glyph == .party)
        #expect(calendar.stamps.isEmpty)
    }
}

extension RecordsModelTests {
    struct Setup {
        let database: AppDatabase
        let today: LocalDate
    }
}

extension RecordsModelTests.Setup {
    init() async throws {
        let database = try AppDatabase.inMemory()
        try database.insertDefaultsIfEmpty(at: Date())
        let today = try #require(LocalDate("2026-10-17"))
        self.init(database: database, today: today)
    }

    func save(
        _ type: Entry.Kind,
        amount: Int,
        on text: String,
        memo: String = ""
    ) async throws {
        let options = try await database.entryOptions()
        let categories = type == .income
            ? options.incomeCategories
            : options.expenseCategories
        let date = try #require(LocalDate(text))
        let days = try await database.entryList().days
        let count = days.reduce(0) { $0 + $1.entries.count }
        let offset = TimeInterval(count)
        let createdAt = Date(timeIntervalSince1970: 1_791_000_000 + offset)

        let draft = EntryDraft(
            type: type,
            amount: amount,
            date: date,
            categoryId: categories.first?.id,
            walletId: options.wallets[0].id,
            memo: memo
        )

        try await database.saveEntry(draft, at: createdAt)
    }
}
