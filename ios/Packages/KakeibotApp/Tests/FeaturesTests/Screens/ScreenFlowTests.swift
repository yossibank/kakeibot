import Core
import FeatureModels
import Foundation
import Store
import Testing
import TestSupport

@MainActor
struct ScreenFlowTests {
    @Test
    func recordedEntryAppearsInEveryTab() async throws {
        let setup = try await Setup()
        let tabs = await setup.openTabs()

        let change = try await setup.record(1200, memo: "ランチ")
        await tabs.wait { $0.entryIDs.allSatisfy { $0 == [change.entry.id] } }
        tabs.close()

        #expect(tabs.home.output.todayExpense == 1200)
        #expect(tabs.home.output.monthExpense == 1200)
        #expect(tabs.home.output.recentRows.map(\.memo) == ["ランチ"])
        #expect(tabs.records.output.days.map(\.date) == [setup.today])
        #expect(tabs.records.output.expenseTotal == 1200)
        #expect(tabs.review.output.total == 1200)
        #expect(tabs.balance(of: setup.cash) == -1200)
        #expect(tabs.assets.output.total == -1200)
    }

    @Test
    func editedEntryMovesToAnotherMonthInEveryTab() async throws {
        let setup = try await Setup()
        let lastMonth = try #require(LocalDate("2026-09-20"))
        let tabs = await setup.openTabs()
        let recorded = try await setup.record(1200)
        let editor = await setup.entryModel(editing: recorded.entry.id)

        editor.state.press(.delete)
        editor.state.setDate(lastMonth)
        let edited = try #require(await editor.save())
        await tabs.wait { $0.amounts.allSatisfy { $0 == [120] } }

        #expect(tabs.home.output.monthExpense == 0)
        #expect(tabs.home.output.recentRows.map(\.amount) == [120])
        #expect(tabs.records.output.days.isEmpty)
        #expect(tabs.review.output.total == 0)
        #expect(tabs.balance(of: setup.cash) == -120)
        #expect(tabs.assets.output.changeFromLastMonth == 0)

        tabs.records.state.move(months: -1)
        tabs.review.move(by: -1)

        #expect(tabs.records.output.days.map(\.date) == [lastMonth])
        #expect(tabs.records.output.expenseTotal == 120)
        #expect(tabs.review.output.total == 120)

        tabs.notice.show(edited)
        await tabs.notice.undo()
        await tabs.wait { $0.amounts.allSatisfy { $0 == [1200] } }
        tabs.records.openCurrentMonth()
        tabs.review.moveToCurrent()
        tabs.close()

        #expect(tabs.notice.state.notice == .undone)
        #expect(tabs.home.output.todayExpense == 1200)
        #expect(tabs.records.output.days.map(\.date) == [setup.today])
        #expect(tabs.review.output.total == 1200)
        #expect(tabs.assets.output.changeFromLastMonth == -1200)
    }

    @Test
    func deletedEntryLeavesEveryTabUntilUndone() async throws {
        let setup = try await Setup()
        let tabs = await setup.openTabs()
        let recorded = try await setup.record(1200, memo: "ランチ")
        let editor = await setup.entryModel(editing: recorded.entry.id)
        await tabs.wait { $0.amounts.allSatisfy { $0 == [1200] } }

        let deleted = try #require(await editor.delete())
        await tabs.wait { $0.amounts.allSatisfy(\.isEmpty) }

        #expect(tabs.home.output.showsNoRecords)
        #expect(tabs.home.output.todayExpense == 0)
        #expect(tabs.records.output.showsNoRecords)
        #expect(tabs.review.output.total == 0)
        #expect(tabs.assets.output.total == 0)

        tabs.notice.show(deleted)
        await tabs.notice.undo()
        await tabs.wait { $0.entryIDs.allSatisfy { $0 == [recorded.entry.id] } }
        tabs.close()

        #expect(tabs.home.output.recentRows.map(\.memo) == ["ランチ"])
        #expect(tabs.home.output.todayExpense == 1200)
        #expect(tabs.records.output.expenseTotal == 1200)
        #expect(tabs.review.output.total == 1200)
        #expect(tabs.assets.output.total == -1200)
    }

    @Test
    func undoneRecordingLeavesEveryTabAndRestoresNoSpendDay() async throws {
        let setup = try await Setup()
        let tabs = await setup.openTabs()
        await tabs.records.toggleNoSpendDay(on: setup.today)
        await tabs.wait { $0.records.input.noSpendDays == [setup.today] }

        let recorded = try await setup.record(500)

        await tabs.wait {
            $0.amounts.allSatisfy { $0 == [500] } && $0.records.input.noSpendDays.isEmpty
        }

        #expect(recorded.clearedNoSpendDays.map(\.date) == [setup.today])

        tabs.notice.show(recorded)
        await tabs.notice.undo()

        await tabs.wait {
            $0.amounts.allSatisfy(\.isEmpty) && $0.records.input.noSpendDays == [setup.today]
        }

        tabs.close()

        #expect(tabs.home.output.showsNoRecords)
        #expect(tabs.records.output.showsNoRecords)
        #expect(tabs.review.output.total == 0)
        #expect(tabs.assets.output.total == 0)
    }

    @Test
    func swipedDeletionKeepsItemsWhenUndone() async throws {
        let setup = try await Setup()
        let tabs = await setup.openTabs()
        let entry = await setup.entryModel()
        entry.state.addItem(name: "牛乳", amount: 250)
        entry.state.addItem(name: "パン", amount: 180)
        let recorded = try #require(await entry.save())
        await tabs.wait { $0.amounts.allSatisfy { $0 == [430] } }

        await tabs.notice.delete(recorded.entry.id, in: tabs.records.input.list)
        await tabs.wait { $0.amounts.allSatisfy(\.isEmpty) }

        #expect(tabs.notice.output.change?.isDeletion == true)
        #expect(tabs.assets.output.total == 0)

        await tabs.notice.undo()
        await tabs.wait { $0.entryIDs.allSatisfy { $0 == [recorded.entry.id] } }
        tabs.close()

        let day = try #require(tabs.records.output.days.first)
        let items = tabs.records.output.rows(for: day).flatMap(\.items)

        #expect(items.map(\.name) == ["牛乳", "パン"])
        #expect(tabs.home.output.recentRows.flatMap(\.items).map(\.amount) == [250, 180])
        #expect(tabs.assets.output.total == -430)
    }

    @Test
    func batchDeletionAndWalletChangeFollowInEveryTab() async throws {
        let setup = try await Setup()
        let tabs = await setup.openTabs()
        let first = try await setup.record(100)
        let second = try await setup.record(200)
        let third = try await setup.record(300)
        let ids = [first, second, third].map(\.entry.id)
        await tabs.wait { $0.amounts.allSatisfy { $0.count == 3 } }
        let order = tabs.entryIDs

        await tabs.notice.changeEntries(ids, to: .wallet(setup.bank))
        await tabs.wait { $0.balance(of: setup.bank) == -600 }

        #expect(tabs.balance(of: setup.cash) == 0)
        #expect(tabs.records.output.expenseTotal == 600)

        await tabs.notice.undo()
        await tabs.wait { $0.balance(of: setup.cash) == -600 }

        #expect(tabs.balance(of: setup.bank) == 0)

        await tabs.notice.deleteEntries(ids)
        await tabs.wait { $0.amounts.allSatisfy(\.isEmpty) }

        #expect(tabs.home.output.todayExpense == 0)
        #expect(tabs.assets.output.total == 0)

        await tabs.notice.undo()
        await tabs.wait { $0.amounts.allSatisfy { $0.count == 3 } }
        tabs.close()

        #expect(tabs.entryIDs == order)
        #expect(tabs.home.output.todayExpense == 600)
        #expect(tabs.review.output.total == 600)
        #expect(tabs.balance(of: setup.cash) == -600)
    }

    @Test
    func entryRecordedFromHomeTemplateAppearsInEveryTabUntilUndone() async throws {
        let setup = try await Setup()
        let templates = TemplateSetup(database: setup.database, date: setup.today)
        let tabs = await setup.openTabs()
        let template = try await templates.saveTemplate(name: "社食", amount: 650)
        await tabs.wait { $0.home.output.templates.map(\.id) == [template.id] }

        let recorded = try #require(await tabs.home.record(template))
        await tabs.wait { $0.amounts.allSatisfy { $0 == [650] } }

        #expect(recorded.label == "社食")
        #expect(tabs.home.output.todayExpense == 650)
        #expect(tabs.records.output.expenseTotal == 650)
        #expect(tabs.review.output.total == 650)
        #expect(tabs.assets.output.total == -650)

        tabs.notice.show(recorded)
        await tabs.notice.undo()
        await tabs.wait { $0.amounts.allSatisfy(\.isEmpty) }
        tabs.close()

        #expect(tabs.home.output.todayExpense == 0)
        #expect(tabs.home.output.templates.map(\.id) == [template.id])
        #expect(tabs.assets.output.total == 0)
    }

    @Test
    func entryDeletedAndRestoredWhileSyncIsOnQueuesItsLatestState() async throws {
        let setup = try await Setup()
        try await setup.database.turnOnSync()
        let tabs = await setup.openTabs()
        let recorded = try await setup.record(1200)
        let key = SyncKey(table: .entry, id: recorded.entry.id.description)
        let editor = await setup.entryModel(editing: recorded.entry.id)

        let deleted = try #require(await editor.delete())
        await tabs.wait { $0.amounts.allSatisfy(\.isEmpty) }
        let afterDeletion = try await setup.database.pendingSyncChanges().filter { $0.key == key }

        #expect(afterDeletion.map(\.isDeletion) == [true])

        tabs.notice.show(deleted)
        await tabs.notice.undo()
        await tabs.wait { $0.entryIDs.allSatisfy { $0 == [recorded.entry.id] } }
        tabs.close()
        let afterUndo = try await setup.database.pendingSyncChanges().filter { $0.key == key }

        #expect(afterUndo.map(\.isDeletion) == [false])
        #expect(afterUndo.map(\.saveZone) == [SyncZone.own])
    }
}
