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
        let model = RecordsModel(database: setup.database, today: setup.today)
        let future = setup.today.adding(days: 1)
        let icon = IconDraft(mark: .glyph(.giftbox), color: "#E07A5F")
        let draft = RewardRuleDraft(name: "自炊した日", amount: 500, icon: icon)
        let rule = try await setup.database.saveRewardRule(draft, at: Date())

        await model.toggleReward(rule, on: future)
        await model.toggleReward(rule, on: setup.today)
        let logs = try setup.database.snapshot().rewardLogs

        #expect(!model.canReward(on: future))
        #expect(model.canReward(on: setup.today))
        #expect(logs.map(\.date) == [setup.today])
    }

    @Test
    func togglesNoSpendDay() async throws {
        let setup = try await Setup()
        let model = RecordsModel(database: setup.database, today: setup.today)

        let task = Task {
            await model.run()
        }

        await model.toggleNoSpendDay(on: setup.today)

        await ObservationWait.until {
            !model.noSpendDays.isEmpty
        }

        let marked = model.noSpendDays
        await model.toggleNoSpendDay(on: setup.today)

        await ObservationWait.until {
            model.noSpendDays.isEmpty
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

        model.setLayout(.list)
        await model.saveLayout()

        let reopened = RecordsModel(database: setup.database, today: setup.today)
        await reopened.loadLayout()

        #expect(reopened.layout == .list)
    }

    @Test
    func opensDayInCalendar() async throws {
        let setup = try await Setup()
        let options = try await setup.database.entryOptions()
        let category = try #require(options.expenseCategories.first?.id)
        let model = RecordsModel(database: setup.database, today: setup.today)
        let date = try #require(LocalDate("2026-08-03"))
        model.setLayout(.list)
        model.isSearching = true
        model.searchText = "ランチ"
        model.filter = EntryFilter(categoryIds: [category])

        model.open(date)

        #expect(model.month.description == "2026-08")
        #expect(model.shownDate == date)
        #expect(model.layout == .calendar)
        #expect(!model.isSearching)
        #expect(model.searchText.isEmpty)
        #expect(model.filter == EntryFilter(categoryIds: [category]))
    }

    @Test
    func opensCurrentMonthWithSearchClosed() async throws {
        let setup = try await Setup()
        let model = RecordsModel(database: setup.database, today: setup.today)
        let selected = try #require(LocalDate("2026-07-03"))
        model.move(months: -3)
        model.selectedDate = selected
        model.isSearching = true
        model.searchText = "ランチ"

        model.openCurrentMonth()

        #expect(model.month.description == "2026-10")
        #expect(model.shownDate == setup.today)
        #expect(!model.isSearching)
        #expect(model.searchText.isEmpty)
    }

    @Test
    func tellsWhetherShownMonthIsCurrent() async throws {
        let setup = try await Setup()
        let model = RecordsModel(database: setup.database, today: setup.today)
        let isCurrentAtFirst = model.isCurrentMonth

        model.move(months: -1)

        #expect(isCurrentAtFirst)
        #expect(!model.isCurrentMonth)
        #expect(model.month < model.currentMonth)
    }

    @Test
    func stampsAndRemovesWithShownChoices() async throws {
        let setup = try await Setup()
        try setup.database.insertShelfIfEmpty(at: Date())
        let shelf = try await setup.database.shelfIconList()
        let hidden = try #require(shelf.shelfIcons.last)
        try await setup.database.setShelfIconHidden(hidden.id, isHidden: true, at: Date())
        let today = setup.today
        let model = RecordsModel(database: setup.database, today: today)

        let task = Task {
            await model.run()
        }

        await ObservationWait.until {
            !model.stampChoices.isEmpty
        }

        let choices = model.stampChoices
        let star = try #require(choices.first)
        let party = try #require(choices.dropFirst().first)

        await model.stamp(star, on: today)
        await model.stamp(party, on: today)

        await ObservationWait.until {
            model.stampIcon(on: today)?.id == party.id
        }

        let stamped = model.stampIcon(on: today)
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
        let model = RecordsModel(database: setup.database, today: setup.today)
        let ids = (0..<10).map { _ in Entry.ID() }
        let firstNine = Array(ids.prefix(9))
        var deleted: [[Entry.ID]] = []

        model.requestDelete(firstNine) {
            deleted.append($0)
        }

        #expect(!model.isConfirmingDelete)
        #expect(deleted == [firstNine])

        deleted = []

        model.requestDelete(ids) {
            deleted.append($0)
        }

        #expect(model.isConfirmingDelete)
        #expect(model.pendingDeleteCount == 10)
        #expect(deleted.isEmpty)

        model.cancelDelete()

        #expect(!model.isConfirmingDelete)
        #expect(deleted.isEmpty)

        model.requestDelete(ids) {
            deleted.append($0)
        }

        model.confirmDelete {
            deleted.append($0)
        }

        #expect(!model.isConfirmingDelete)
        #expect(deleted == [ids])
    }
}
