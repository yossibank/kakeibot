import Core
import Features
import Foundation
import Store
import Testing

@MainActor
struct TemplateEditModelTests {
    @Test
    func keepsOnlyDigitsInAmount() throws {
        let model = try TemplateEditModel(database: Self.database())

        model.inputAmount("0¥1,280")
        let typed = model.amount

        model.inputAmount("")

        #expect(typed == 1280)
        #expect(model.amount == nil)
    }

    @Test
    func savesNewTemplateWithDefaults() async throws {
        let database = try Self.database()
        let model = TemplateEditModel(database: database)
        await model.load()
        let canSaveWithoutName = model.canSave
        model.name = "ランチ"
        model.inputAmount("980")

        let saved = await model.save()
        let templates = try await database.templates()

        #expect(!canSaveWithoutName)
        #expect(saved?.amount == 980)
        #expect(templates.map(\.name) == ["ランチ"])
        #expect(templates.first?.categoryId == model.categoryId)
    }

    @Test
    func loadsExistingTemplateAndTracksChanges() async throws {
        let database = try Self.database()
        let creator = TemplateEditModel(database: database)
        await creator.load()
        creator.name = "定期"
        let saved = try #require(await creator.save())

        let model = TemplateEditModel(database: database, editing: saved.id)
        await model.load()
        let loaded = model.isChanged

        model.memo = "通勤"

        #expect(model.name == "定期")
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
