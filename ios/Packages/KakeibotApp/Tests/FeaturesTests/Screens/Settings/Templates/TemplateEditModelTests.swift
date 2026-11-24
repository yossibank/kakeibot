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
        let model = TemplateEditModel(database: database, clock: .system, type: .income)

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
    func namesWhatIsMissingOnSaveButton() async throws {
        let database = try Self.database()
        let model = TemplateEditModel(database: database, clock: .system, type: .expense)
        await model.load()

        let empty = model.saveTitle
        model.state.name = "ランチ"

        #expect(empty == "名前を入れてください")
        #expect(model.saveTitle == "追加する")
    }

    @Test
    func savesNewTemplateWithDefaults() async throws {
        let database = try Self.database()
        let model = TemplateEditModel(database: database, clock: .system, type: .expense)
        await model.load()
        let canSaveWithoutName = model.canSave
        let refused = await model.save()
        let refusal = model.state.errorNotice.message
        model.state.name = "ランチ"
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
        let creator = TemplateEditModel(database: database, clock: .system, type: .income)
        await creator.load()
        creator.state.name = "定期"
        let saved = try #require(await creator.save())
        let model = TemplateEditModel(
            database: database,
            clock: .system,
            type: .expense,
            editing: saved.id
        )

        await model.load()
        let loaded = model.isChanged

        model.state.memo = "通勤"

        #expect(model.state.name == "定期")
        #expect(model.state.type == .income)
        #expect(model.output.selectedCategory?.id == saved.categoryId)
        #expect(model.output.selectedWallet?.id == saved.walletId)
        #expect(model.output.amount == nil)
        #expect(!loaded)
        #expect(model.isChanged)
    }
}

private extension TemplateEditModelTests {
    static func database() throws -> AppDatabase {
        let database = try AppDatabase.inMemory()
        try database.insertDefaultsIfEmpty(at: Date())
        return database
    }
}
