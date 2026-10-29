import Core
import Features
import Store
import Testing

@MainActor
struct HomeSectionsModelTests {
    @Test
    func loadsStandardLayout() async throws {
        let database = try AppDatabase.inMemory()
        let model = HomeSectionsModel(database: database)

        await model.load()

        #expect(model.isLoaded)
        #expect(model.layout == .standard)
    }

    @Test
    func savesMovedSection() async throws {
        let database = try AppDatabase.inMemory()
        let model = HomeSectionsModel(database: database)
        await model.load()

        model.move(.recent, toSlot: 0)
        await model.save()
        let order = try await database.setting(.homeSections)
        let reloaded = HomeSectionsModel(database: database)
        await reloaded.load()

        #expect(order.first == .recent)
        #expect(reloaded.layout == model.layout)
    }

    @Test
    func tellsWhenLayoutCannotBeSaved() async throws {
        let database = try AppDatabase.inMemory()
        let model = HomeSectionsModel(database: database)
        await model.load()
        model.move(.recent, toSlot: 0)
        try await database.failWrites(to: "setting")

        await model.save()
        let order = try await database.setting(.homeSections)

        #expect(model.errorNotice.message == "設定を保存できませんでした")
        #expect(order == HomeSection.standard)
    }
}
