import Core
import Features
import Foundation
import Store
import Testing

extension EntryModelTests {
    @Test
    func appliesTemplateToEntry() async throws {
        let setup = try await TemplateSetup()
        let lunch = try await setup.saveTemplate(name: "ランチ", amount: 980)
        let model = EntryModel(database: setup.database, date: setup.date)
        await model.load()

        model.apply(lunch)
        let saved = await model.save()

        #expect(model.amount == 980)
        #expect(model.memo == "社食")
        #expect(model.categoryId == lunch.categoryId)
        #expect(model.isApplied(lunch))
        #expect(saved?.entry.templateId == lunch.id)
    }

    @Test
    func keepsTypedAmountAndMemoWhenTemplateLacksThem() async throws {
        let setup = try await TemplateSetup()
        let pass = try await setup.saveTemplate(name: "定期", amount: nil, memo: "")
        let model = EntryModel(database: setup.database, date: setup.date)
        await model.load()
        model.press(.digit(4))
        model.press(.digit(5))
        model.press(.digit(0))
        model.memo = "カフェ"

        model.apply(pass)

        #expect(model.amount == 450)
        #expect(model.memo == "カフェ")
        #expect(model.categoryId == pass.categoryId)
        #expect(model.isApplied(pass))
    }

    @Test
    func dropsArchivedTagWhenApplyingTemplate() async throws {
        let setup = try await TemplateSetup()
        let tag = try await setup.saveTag("買い置き")
        let stock = try await setup.saveTemplate(name: "買い置き", amount: 500, tagId: tag.id)
        try await setup.database.saveTags([], for: tag.categoryId, at: Date())
        let model = EntryModel(database: setup.database, date: setup.date)
        await model.load()

        model.apply(stock)

        #expect(model.tagId == nil)
        #expect(model.isApplied(stock))
    }

    @Test
    func dropsArchivedTagAndTemplateWhenRecordingAgain() async throws {
        let setup = try await TemplateSetup()
        let tag = try await setup.saveTag("買い置き")
        let stock = try await setup.saveTemplate(name: "買い置き", amount: 500, tagId: tag.id)
        let first = EntryModel(database: setup.database, date: setup.date)
        await first.load()
        first.apply(stock)
        let entry = try #require(await first.save()?.entry)
        try await setup.database.saveTags([], for: tag.categoryId, at: Date())
        let model = EntryModel(database: setup.database, editing: entry.id, date: setup.date)
        await model.load()

        await model.recordAgain()
        let saved = await model.save()

        #expect(entry.tagId == tag.id)
        #expect(entry.templateId == stock.id)
        #expect(saved?.entry.id != entry.id)
        #expect(saved?.entry.tagId == nil)
        #expect(saved?.entry.templateId == nil)
    }

    @Test
    func appliesTagAndDropsItWithOtherCategory() async throws {
        let setup = try await TemplateSetup()
        let tag = try await setup.saveTag("買い置き")
        let stock = try await setup.saveTemplate(name: "買い置き", amount: 1200, tagId: tag.id)
        let model = EntryModel(database: setup.database, date: setup.date)
        await model.load()

        model.apply(stock)
        let applied = model.tagId
        let tags = model.tags.map(\.name)
        let saved = await model.save()
        let entry = try await setup.database.entryList().days.first?.entries

        model.categoryId = model.categories.first?.id

        #expect(applied == tag.id)
        #expect(tags == ["買い置き"])
        #expect(saved?.entry.tagId == tag.id)
        #expect(entry?.first?.tagId == tag.id)
        #expect(model.tagId == nil)
        #expect(!model.isApplied(stock))
    }

    @Test
    func highlightsOnlyTheAppliedTemplate() async throws {
        let setup = try await TemplateSetup()
        let pass = try await setup.saveTemplate(name: "定期", amount: nil)
        let bus = try await setup.saveTemplate(name: "バス", amount: nil)
        let model = EntryModel(database: setup.database, date: setup.date)
        await model.load()

        model.apply(bus)

        #expect(model.isApplied(bus))
        #expect(!model.isApplied(pass))
    }

    @Test
    func startsFromTemplateWithoutChanges() async throws {
        let setup = try await TemplateSetup()
        let pass = try await setup.saveTemplate(name: "定期", amount: nil)
        try await setup.saveTemplate(name: "給料", amount: nil, type: .income)
        let model = EntryModel(database: setup.database, date: setup.date, template: pass)

        await model.load()

        #expect(model.amount == 0)
        #expect(model.memo == "社食")
        #expect(!model.isChanged)
        #expect(model.templates.map(\.name) == ["定期"])
    }

    @Test
    func prefillsNewTemplateFromInput() async throws {
        let setup = try await TemplateSetup()
        let model = EntryModel(database: setup.database, date: setup.date)
        await model.load()
        model.press(.digit(4))
        model.press(.digit(5))
        model.press(.digit(0))
        model.memo = "カフェ"

        let editor = model.newTemplateModel()

        #expect(editor.amount == 450)
        #expect(editor.memo == "カフェ")
        #expect(editor.categoryId == model.categoryId)
        #expect(editor.name.isEmpty)
    }
}
