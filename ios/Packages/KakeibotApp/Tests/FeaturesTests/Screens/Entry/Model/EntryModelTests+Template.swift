import Core
import FeatureModels
import Features
import Foundation
import Store
import Testing

extension EntryModelTests {
    @Test
    func showsTemplateIconWhileSharedWalletIsChosen() async throws {
        let setup = try await TemplateSetup()
        let salary = try await setup.saveTemplate(name: "給料", amount: 300_000, type: .income)
        let shared = try await setup.database.entryOptions().wallets[1]
        try await setup.database.startSharing(shared.id)
        let model = EntryModel(
            database: setup.database,
            clock: .system,
            date: setup.date,
            type: .income
        )
        await model.load()

        model.setWallet(shared.id)

        #expect(model.output.icon(for: salary) != nil)
    }

    @Test
    func appliesTemplateToEntry() async throws {
        let setup = try await TemplateSetup()
        let lunch = try await setup.saveTemplate(name: "ランチ", amount: 980)
        let model = EntryModel(database: setup.database, clock: .system, date: setup.date)
        await model.load()

        model.apply(lunch)
        let saved = await model.save()

        #expect(model.output.amount == 980)
        #expect(model.state.memo == "社食")
        #expect(model.state.category.id == lunch.categoryId)
        #expect(model.output.isApplied(lunch))
        #expect(saved?.entry.templateId == lunch.id)
    }

    @Test
    func keepsTypedAmountAndMemoWhenTemplateLacksThem() async throws {
        let setup = try await TemplateSetup()
        let pass = try await setup.saveTemplate(name: "定期", amount: nil, memo: "")
        let model = EntryModel(database: setup.database, clock: .system, date: setup.date)
        await model.load()
        model.state.press(.digit(4))
        model.state.press(.digit(5))
        model.state.press(.digit(0))
        model.state.memo = "カフェ"

        model.apply(pass)

        #expect(model.output.amount == 450)
        #expect(model.state.memo == "カフェ")
        #expect(model.state.category.id == pass.categoryId)
        #expect(model.output.isApplied(pass))
    }

    @Test
    func dropsArchivedTagWhenApplyingTemplate() async throws {
        let setup = try await TemplateSetup()
        let tag = try await setup.saveTag("買い置き")
        let stock = try await setup.saveTemplate(name: "買い置き", amount: 500, tagId: tag.id)
        _ = try await setup.database.saveTags([], for: tag.categoryId, at: Date())
        let model = EntryModel(database: setup.database, clock: .system, date: setup.date)
        await model.load()

        model.apply(stock)

        #expect(model.state.category.tagId == nil)
        #expect(model.output.isApplied(stock))
    }

    @Test
    func dropsArchivedTagAndTemplateWhenRecordingAgain() async throws {
        let setup = try await TemplateSetup()
        let tag = try await setup.saveTag("買い置き")
        let stock = try await setup.saveTemplate(name: "買い置き", amount: 500, tagId: tag.id)
        let first = EntryModel(database: setup.database, clock: .system, date: setup.date)
        await first.load()
        first.apply(stock)
        let entry = try #require(await first.save()?.entry)
        _ = try await setup.database.saveTags([], for: tag.categoryId, at: Date())
        let model = EntryModel(
            database: setup.database,
            clock: .system,
            editing: entry.id,
            date: setup.date
        )
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
        let model = EntryModel(database: setup.database, clock: .system, date: setup.date)
        await model.load()

        model.apply(stock)
        let applied = model.state.category.tagId
        let tags = model.output.tags.map(\.name)
        let saved = await model.save()
        let entry = try await setup.database.entryList().days.first?.entries

        model.state.setCategory(model.output.categories.first?.id)

        #expect(applied == tag.id)
        #expect(tags == ["買い置き"])
        #expect(saved?.entry.tagId == tag.id)
        #expect(entry?.first?.tagId == tag.id)
        #expect(model.state.category.tagId == nil)
        #expect(!model.output.isApplied(stock))
    }

    @Test
    func highlightsOnlyTheAppliedTemplate() async throws {
        let setup = try await TemplateSetup()
        let pass = try await setup.saveTemplate(name: "定期", amount: nil)
        let bus = try await setup.saveTemplate(name: "バス", amount: nil)
        let model = EntryModel(database: setup.database, clock: .system, date: setup.date)
        await model.load()

        model.apply(bus)

        #expect(model.output.isApplied(bus))
        #expect(!model.output.isApplied(pass))
    }

    @Test
    func startsFromTemplateWithoutChanges() async throws {
        let setup = try await TemplateSetup()
        let pass = try await setup.saveTemplate(name: "定期", amount: nil)
        try await setup.saveTemplate(name: "給料", amount: nil, type: .income)
        let model = EntryModel(
            database: setup.database,
            clock: .system,
            date: setup.date,
            template: pass
        )

        await model.load()

        #expect(model.output.amount == 0)
        #expect(model.state.memo == "社食")
        #expect(!model.output.isChanged)
        #expect(model.output.templates.map(\.name) == ["定期"])
    }

    @Test
    func prefillsNewTemplateFromInput() async throws {
        let setup = try await TemplateSetup()
        let model = EntryModel(database: setup.database, clock: .system, date: setup.date)
        await model.load()
        model.state.press(.digit(4))
        model.state.press(.digit(5))
        model.state.press(.digit(0))
        model.state.memo = "カフェ"

        let editor = model.newTemplateModel()

        #expect(editor.output.amount == 450)
        #expect(editor.state.memo == "カフェ")
        #expect(editor.state.categoryId == model.state.category.id)
        #expect(editor.state.name.isEmpty)
    }
}
