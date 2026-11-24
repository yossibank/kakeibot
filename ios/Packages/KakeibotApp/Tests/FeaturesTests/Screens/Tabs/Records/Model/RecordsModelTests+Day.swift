import Core
import Features
import Foundation
import Store
import Testing
import TestSupport

extension RecordsModelTests {
    @Test
    func refusesRewardOnFutureDay() async throws {
        let setup = try await Setup()
        let model = RecordsModel(database: setup.database, clock: .system, today: setup.today)
        let future = setup.today.adding(days: 1)
        let icon = IconDraft(mark: .glyph(.giftbox), color: "#E07A5F")
        let draft = RewardRuleDraft(name: "自炊した日", amount: 500, icon: icon)
        let rule = try await setup.database.save(draft, at: Date())

        await model.toggleReward(rule, on: future)
        await model.toggleReward(rule, on: setup.today)
        let logs = try setup.database.snapshot().rewardLogs

        #expect(!model.output.canReward(on: future))
        #expect(model.output.canReward(on: setup.today))
        #expect(logs.map(\.date) == [setup.today])
    }

    @Test
    func togglesNoSpendDay() async throws {
        let setup = try await Setup()
        let model = RecordsModel(database: setup.database, clock: .system, today: setup.today)

        let task = Task {
            await model.run()
        }

        await model.toggleNoSpendDay(on: setup.today)

        await ObservationWait.until {
            !model.input.noSpendDays.isEmpty
        }

        let marked = model.input.noSpendDays
        await model.toggleNoSpendDay(on: setup.today)

        await ObservationWait.until {
            model.input.noSpendDays.isEmpty
        }

        let unmarked = model.input.noSpendDays
        task.cancel()

        #expect(marked == [setup.today])
        #expect(unmarked.isEmpty)
    }

    @Test
    func remembersLayout() async throws {
        let setup = try await Setup()
        let model = RecordsModel(database: setup.database, clock: .system, today: setup.today)

        model.chooseLayout(.list)
        await model.saveLayout()

        let reopened = RecordsModel(database: setup.database, clock: .system, today: setup.today)
        await reopened.loadLayout()

        #expect(reopened.input.layout == .list)
    }

    @Test
    func opensDayInCalendar() async throws {
        let setup = try await Setup()
        let options = try await setup.database.entryOptions()
        let category = try #require(options.expenseCategories.first?.id)
        let model = RecordsModel(database: setup.database, clock: .system, today: setup.today)
        let date = try #require(LocalDate("2026-08-03"))
        model.chooseLayout(.list)
        model.state.isSearching = true
        model.state.searchText = "ランチ"
        model.state.filter = EntryFilter(categoryIds: [category])

        model.open(date)

        #expect(model.state.month.description == "2026-08")
        #expect(model.output.shownDate == date)
        #expect(model.input.layout == .calendar)
        #expect(!model.state.isSearching)
        #expect(model.state.searchText.isEmpty)
        #expect(model.state.filter == EntryFilter(categoryIds: [category]))
    }

    @Test
    func opensCurrentMonthWithSearchClosed() async throws {
        let setup = try await Setup()
        let model = RecordsModel(database: setup.database, clock: .system, today: setup.today)
        let selected = try #require(LocalDate("2026-07-03"))
        model.state.move(months: -3)
        model.state.selectedDate = selected
        model.state.isSearching = true
        model.state.searchText = "ランチ"

        model.openCurrentMonth()

        #expect(model.state.month.description == "2026-10")
        #expect(model.output.shownDate == setup.today)
        #expect(!model.state.isSearching)
        #expect(model.state.searchText.isEmpty)
    }

    @Test
    func tellsWhetherShownMonthIsCurrent() async throws {
        let setup = try await Setup()
        let model = RecordsModel(database: setup.database, clock: .system, today: setup.today)
        let isCurrentAtFirst = model.output.isCurrentMonth

        model.state.move(months: -1)

        #expect(isCurrentAtFirst)
        #expect(!model.output.isCurrentMonth)
        #expect(model.state.month < model.output.currentMonth)
    }

    @Test
    func stampsAndRemovesWithShownChoices() async throws {
        let setup = try await Setup()
        try setup.database.insertShelfIfEmpty(at: Date())
        let shelf = try await setup.database.shelfIconList()
        let hidden = try #require(shelf.shelfIcons.last)
        try await setup.database.setHidden(hidden.id, isHidden: true, at: Date())
        let today = setup.today
        let model = RecordsModel(database: setup.database, clock: .system, today: today)

        let task = Task {
            await model.run()
        }

        await ObservationWait.until {
            !model.output.stampChoices.isEmpty
        }

        let choices = model.output.stampChoices
        let star = try #require(choices.first)
        let party = try #require(choices.dropFirst().first)

        await model.stamp(star, on: today)
        await model.stamp(party, on: today)

        await ObservationWait.until {
            model.output.stampIcon(on: today)?.id == party.id
        }

        let stamped = model.output.stampIcon(on: today)
        await model.removeStamp(on: today)
        let calendar = try await setup.database.stampBook()
        task.cancel()

        #expect(choices.count == 7)
        #expect(!choices.contains { $0.id == hidden.iconId })
        #expect(stamped?.glyph == .party)
        #expect(calendar.stamps.isEmpty)
    }

    @Test
    func confirmsBatchDeleteOfTenOrMore() async throws {
        let setup = try await Setup()
        let model = RecordsModel(database: setup.database, clock: .system, today: setup.today)
        let ids = (0..<10).map { _ in Entry.ID() }
        let firstNine = Array(ids.prefix(9))
        var deleted: [[Entry.ID]] = []

        model.state.requestDelete(firstNine) {
            deleted.append($0)
        }

        #expect(!model.state.isConfirmingDelete)
        #expect(deleted == [firstNine])

        deleted = []

        model.state.requestDelete(ids) {
            deleted.append($0)
        }

        #expect(model.state.isConfirmingDelete)
        #expect(model.output.pendingDeleteCount == 10)
        #expect(deleted.isEmpty)

        model.state.cancelDelete()

        #expect(!model.state.isConfirmingDelete)
        #expect(deleted.isEmpty)

        model.state.requestDelete(ids) {
            deleted.append($0)
        }

        model.state.confirmDelete {
            deleted.append($0)
        }

        #expect(!model.state.isConfirmingDelete)
        #expect(deleted == [ids])
    }
}
