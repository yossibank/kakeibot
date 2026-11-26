import Core
@testable import FeatureModels
@testable import Features
import Foundation
import Store
import Testing

@MainActor
struct TemplateEditModelTests {
    @Test
    func entersAmountWithKeypad() throws {
        let database = try Self.database()
        let model = TemplateEditModel(parts: .system(database), type: .income)

        model.state.press(.digit(1))
        model.state.press(.doubleZero)
        let typed = model.output.amount

        model.state.press(.clear)

        #expect(typed == 100)
        #expect(model.output.amount == nil)
        #expect(model.output.typeName == "収入")
        #expect(model.output.walletTitle == "入金先")
    }

    @Test
    func opensOnePanelAtATime() throws {
        let database = try Self.database()
        let model = TemplateEditModel(parts: .system(database), type: .expense)

        model.state.panel.show(.amount)
        model.state.panel.show(.memo)
        let opened = model.state.panel.current

        model.state.panel.closeAll()

        #expect(opened == .memo)
        #expect(model.state.panel.current == nil)
        #expect(model.state.tagCategory.current == nil)
    }

    @Test
    func namesWhatIsMissingOnSaveButton() async throws {
        let database = try Self.database()
        let model = TemplateEditModel(parts: .system(database), type: .expense)
        await model.load()

        let empty = model.flow.output.saveTitle
        model.state.fields.name = "ランチ"

        #expect(empty == "名前を入れてください")
        #expect(model.flow.output.saveTitle == "追加する")
    }

    @Test
    func savesNewTemplateWithDefaults() async throws {
        let database = try Self.database()
        let model = TemplateEditModel(parts: .system(database), type: .expense)
        await model.load()
        let canSaveWithoutName = model.flow.output.canSave
        let refused = await model.save()
        let refusal = model.state.errorNotice.message
        model.state.fields.name = "ランチ"
        model.state.press(.digit(9))
        model.state.press(.digit(8))
        model.state.press(.digit(0))

        let saved = await model.save()
        let templates = try await database.templates()

        #expect(!canSaveWithoutName)
        #expect(refused == nil)
        #expect(refusal == "名前を入れてください")
        #expect(saved?.amount == 980)
        #expect(templates.map(\.name) == ["ランチ"])
        #expect(templates.first?.categoryId == model.state.categoryId)
    }

    @Test
    func loadsExistingTemplateAndTracksChanges() async throws {
        let database = try Self.database()
        let creator = TemplateEditModel(parts: .system(database), type: .income)
        await creator.load()
        creator.state.fields.name = "定期"
        let saved = try #require(await creator.save())
        let model = TemplateEditModel(
            parts: .system(database),
            type: .expense,
            editing: saved.id
        )

        await model.load()
        let loaded = model.flow.output.isChanged

        model.state.fields.memo = "通勤"

        #expect(model.state.fields.name == "定期")
        #expect(model.state.type == .income)
        #expect(model.output.selectedCategory?.id == saved.categoryId)
        #expect(model.output.selectedWallet?.id == saved.walletId)
        #expect(model.output.amount == nil)
        #expect(!loaded)
        #expect(model.flow.output.isChanged)
    }

    @Test
    func asksBeforeDiscardingChanges() async throws {
        let database = try Self.database()
        let model = TemplateEditModel(parts: .system(database), type: .expense)
        await model.load()

        let changedAfterLoad = model.flow.output.isChanged
        model.state.fields.name = "ランチ"

        model.flow.close()
        let asked = model.flow.state.prompt.isShowing(.discard)
        let pending = model.flow.state.outcome.value

        model.flow.discard()

        #expect(!changedAfterLoad)
        #expect(asked)
        #expect(pending == nil)
        #expect(model.flow.state.outcome.value?.closes == true)
    }

    @Test
    func keepsNoticeWhenInputChanges() async throws {
        let database = try Self.database()
        let model = TemplateEditModel(parts: .system(database), type: .expense)
        await model.load()
        await model.save()

        model.state.press(.digit(9))

        #expect(model.state.errorNotice.message == "名前を入れてください")
    }
}

private extension TemplateEditModelTests {
    static func database() throws -> AppDatabase {
        let database = try AppDatabase.inMemory()
        try database.insertDefaultsIfEmpty(at: Date())
        return database
    }
}
