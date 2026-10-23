import Core
import Features
import Foundation
import Store
import Testing

@MainActor
struct TemplateEditModelTests {
    @Test
    func entersAmountWithKeypad() throws {
        let database = try Self.database()
        let model = TemplateEditModel(database: database, type: .income)

        model.press(.digit(1))
        model.press(.doubleZero)
        let typed = model.amount

        model.press(.clear)

        #expect(typed == 100)
        #expect(model.amount == nil)
        #expect(model.typeName == "収入")
        #expect(model.walletTitle == "入金先")
    }

    @Test
    func namesWhatIsMissingOnSaveButton() async throws {
        let database = try Self.database()
        let model = TemplateEditModel(database: database, type: .expense)
        await model.load()

        let empty = model.saveTitle
        model.name = "ランチ"

        #expect(empty == "名前を入れてください")
        #expect(model.saveTitle == "追加する")
    }

    @Test
    func savesNewTemplateWithDefaults() async throws {
        let database = try Self.database()
        let model = TemplateEditModel(database: database, type: .expense)
        await model.load()
        let canSaveWithoutName = model.canSave
        let refused = await model.save()
        let refusal = model.errorNotice.message
        model.name = "ランチ"
        model.press(.digit(9))
        model.press(.digit(8))
        model.press(.digit(0))

        let saved = await model.save()
        let templates = try await database.templates()

        #expect(!canSaveWithoutName)
        #expect(refused == nil)
        #expect(refusal == "名前を入れてください")
        #expect(saved?.amount == 980)
        #expect(templates.map(\.name) == ["ランチ"])
        #expect(templates.first?.categoryId == model.categoryId)
    }

    @Test
    func loadsExistingTemplateAndTracksChanges() async throws {
        let database = try Self.database()
        let creator = TemplateEditModel(database: database, type: .income)
        await creator.load()
        creator.name = "定期"
        let saved = try #require(await creator.save())

        let model = TemplateEditModel(
            database: database,
            type: .expense,
            editing: saved.id
        )

        await model.load()
        let loaded = model.isChanged

        model.memo = "通勤"

        #expect(model.name == "定期")
        #expect(model.type == .income)
        #expect(model.selectedCategory?.id == saved.categoryId)
        #expect(model.selectedWallet?.id == saved.walletId)
        #expect(model.amount == nil)
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
