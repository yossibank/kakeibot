import Core
import FeatureModels
import Features
import Store
import Testing

@MainActor
struct HomeSectionListModelTests {
    @Test
    func loadsStandardLayout() async throws {
        let database = try AppDatabase.inMemory()
        let model = HomeSectionListModel(parts: .system(database))

        await model.load()

        #expect(model.input.saved == .loaded(.standard))
        #expect(model.state.layout == .standard)
    }

    @Test
    func savesMovedSection() async throws {
        let database = try AppDatabase.inMemory()
        let model = HomeSectionListModel(parts: .system(database))
        await model.load()

        model.move(.recent, toSlot: 0)
        await model.save()
        let order = try await database.setting(.homeSections)
        let reloaded = HomeSectionListModel(parts: .system(database))
        await reloaded.load()

        #expect(order.first == .recent)
        #expect(reloaded.state.layout == model.state.layout)
    }

    @Test
    func tellsWhenLayoutCannotBeSaved() async throws {
        let database = try AppDatabase.inMemory()
        let model = HomeSectionListModel(parts: .system(database))
        await model.load()
        model.move(.recent, toSlot: 0)
        try await database.failWrites(to: "setting")

        await model.save()
        let order = try await database.setting(.homeSections)

        #expect(model.state.notices.error.message == "設定を保存できませんでした")
        #expect(order == HomeSection.standard)
    }
}

extension HomeSectionListModelTests {
    @Test
    func movesDraggedSectionFromWhereItStarted() async throws {
        let database = try AppDatabase.inMemory()
        let model = HomeSectionListModel(parts: .system(database))
        await model.load()
        let moved = try #require(model.state.layout.slots.compactMap(\.section).last)
        let other = try #require(model.state.layout.slots.compactMap(\.section).first)
        let start = try #require(model.state.layout.slots.firstIndex(of: .section(moved)))

        model.startDragging(moved)
        model.startDragging(other)
        let dragging = model.state.dragging

        model.moveDragging(bySlots: -start)
        let isFinished = model.finishDragging()
        let isFinishedAgain = model.finishDragging()

        #expect(dragging?.section == moved)
        #expect(dragging?.start == start)
        #expect(model.state.layout.slots.first == .section(moved))
        #expect(isFinished)
        #expect(!isFinishedAgain)
        #expect(model.state.dragging == nil)
    }
}
