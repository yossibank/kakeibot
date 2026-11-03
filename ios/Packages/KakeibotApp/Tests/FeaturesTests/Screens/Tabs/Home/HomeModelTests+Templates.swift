import Core
import Features
import Foundation
import Store
import Testing
import TestSupport

extension HomeModelTests {
    @Test
    func groupsAndSearchesTemplatesByCategory() async throws {
        let setup = try await TemplateSetup()
        try await setup.saveTemplate(name: "洗剤", amount: 400)
        try await setup.saveTemplate(name: "ティッシュ", amount: 300)
        let options = try await setup.database.entryOptions()

        let cafe = EntryTemplateDraft(
            name: "駅前のカフェでモーニング",
            type: .expense,
            amount: 650,
            categoryId: options.expenseCategories[0].id,
            walletId: options.wallets[0].id,
            memo: ""
        )

        try await setup.database.saveTemplate(cafe, at: Date())
        let home = HomeModel(database: setup.database, today: setup.date)

        let task = Task {
            await home.run()
        }

        await ObservationWait.until {
            home.templates.count >= 3 && home.list != nil
        }

        let all = home.templateSections(matching: "")
        let found = home.templateSections(matching: " カフェ ")
        task.cancel()

        #expect(all.map(\.title) == ["食費", "日用品"])
        #expect(all.last?.templates.map(\.name) == ["洗剤", "ティッシュ"])
        #expect(found.map(\.title) == ["食費"])
        #expect(found.first?.templates.map(\.name) == ["駅前のカフェでモーニング"])
    }

    @Test
    func ordersTemplatesAndRemembersTheOrder() async throws {
        let setup = try await TemplateSetup()
        try await setup.saveTemplate(name: "洗剤", amount: 400)
        try await setup.saveTemplate(name: "ティッシュ", amount: 900)
        let options = try await setup.database.entryOptions()

        let cafe = EntryTemplateDraft(
            name: "駅前のカフェでモーニング",
            type: .expense,
            amount: 650,
            categoryId: options.expenseCategories[0].id,
            walletId: options.wallets[0].id,
            memo: ""
        )

        try await setup.database.saveTemplate(cafe, at: Date())
        let home = HomeModel(database: setup.database, today: setup.date)

        let task = Task {
            await home.run()
        }

        await ObservationWait.until {
            home.templates.count >= 3 && home.list != nil
        }

        let manual = home.templates.map(\.name)
        await home.setTemplateOrder(.category)
        let category = home.templates.map(\.name)
        await home.setTemplateOrder(.amount)
        let amount = home.templates.map(\.name)
        await home.setTemplateOrder(.name)
        let name = home.templates.map(\.name)
        task.cancel()

        let reopened = HomeModel(database: setup.database, today: setup.date)
        await reopened.loadTemplateOrder()

        #expect(manual == ["洗剤", "ティッシュ", "駅前のカフェでモーニング"])
        #expect(category == ["駅前のカフェでモーニング", "洗剤", "ティッシュ"])
        #expect(amount == ["ティッシュ", "駅前のカフェでモーニング", "洗剤"])
        #expect(name == ["ティッシュ", "駅前のカフェでモーニング", "洗剤"])
        #expect(reopened.templateOrder == .name)
    }

    @Test
    func ordersTemplatesByUsesInNinetyDays() async throws {
        let setup = try await TemplateSetup()
        let soap = try await setup.saveTemplate(name: "洗剤", amount: 400)
        let tissue = try await setup.saveTemplate(name: "ティッシュ", amount: 300)
        let oldDate = setup.date.adding(days: -90)
        let old = try #require(soap.entryDraft(on: oldDate))
        try await setup.database.saveEntry(old, at: Date())
        try await setup.database.saveEntry(old, at: Date())
        let home = HomeModel(database: setup.database, today: setup.date)

        let task = Task {
            await home.run()
        }

        await ObservationWait.until {
            home.templates.count >= 2 && home.list != nil
        }

        _ = await home.record(tissue)

        await ObservationWait.until {
            home.list?.days.count ?? 0 >= 2
        }

        await home.setTemplateOrder(.frequent)
        let names = home.templates.map(\.name)
        task.cancel()

        #expect(names == ["ティッシュ", "洗剤"])
    }

    @Test
    func showsTemplatesOfSelectedTypeOnHome() async throws {
        let setup = try await TemplateSetup()
        try await setup.saveTemplate(name: "ランチ", amount: 980)
        try await setup.saveTemplate(name: "給料", amount: nil, type: .income)
        let home = HomeModel(database: setup.database, today: setup.date)

        let task = Task {
            await home.run()
        }

        await ObservationWait.until {
            !home.templates.isEmpty
        }

        let expense = home.templates.map(\.name)
        home.templateType = .income
        let income = home.templates.map(\.name)
        task.cancel()

        #expect(expense == ["ランチ"])
        #expect(income == ["給料"])
    }

    @Test
    func recordsFromHomeWithoutArchivedTag() async throws {
        let setup = try await TemplateSetup()
        let tag = try await setup.saveTag("朝ごはん")
        let lunch = try await setup.saveTemplate(name: "ランチ", amount: 980, tagId: tag.id)
        let home = HomeModel(database: setup.database, today: setup.date)

        let kept = try #require(await home.record(lunch))

        try await setup.database.saveTags([], for: tag.categoryId, at: Date())
        let dropped = try #require(await home.record(lunch))

        #expect(kept.entry.tagId == tag.id)
        #expect(dropped.entry.tagId == nil)
    }

    @Test
    func recordsFromHomeAndUndoes() async throws {
        let setup = try await TemplateSetup()
        let lunch = try await setup.saveTemplate(name: "ランチ", amount: 980)
        let home = HomeModel(database: setup.database, today: setup.date)
        let notice = EntryNoticeModel(database: setup.database)

        let change = try #require(await home.record(lunch))
        notice.show(change)
        let afterRecord = try await setup.database.entryList()

        await notice.undo()
        let afterUndo = try await setup.database.entryList()

        #expect(change.message == "ランチ ¥980 を記録しました")
        #expect(afterRecord.days.first?.entries.first?.amount == 980)
        #expect(afterRecord.days.first?.date == setup.date)
        #expect(afterUndo.days.isEmpty)
        #expect(notice.change == nil)
    }
}
