import Core
import FeatureModels
import Features
import Foundation
import Store
import Testing

extension HomeModelTests {
    @Test
    func opensPickedDayAfterClosingStampSheet() async throws {
        let setup = try await RecordsModelTests.Setup()
        try setup.database.insertShelfIfEmpty(at: Date())
        let shelf = try await setup.database.shelfIconList().shelfIcons
        let star = try #require(shelf.first?.iconId)
        let date = try #require(LocalDate("2026-10-05"))
        try await setup.database.stamp(star, on: date, at: Date())
        let book = try await setup.database.stampBook()
        let month = try #require(LocalDate("2026-10-01"))...setup.today
        let tally = try #require(book.tallies(in: month).first)
        let model = HomeModel(parts: .system(setup.database), today: setup.today)

        let empty = model.state.takePendingDay()

        model.state.presented.stamp.show(tally)
        model.state.pickStampDay(date)

        let first = model.state.takePendingDay()
        let second = model.state.takePendingDay()

        #expect(empty == nil)
        #expect(model.state.presented.stamp.current == nil)
        #expect(first == date)
        #expect(second == nil)
    }

    @Test
    func startsShelfOverAfterClosing() async throws {
        let setup = try await Setup()
        let model = HomeModel(parts: .system(setup.database), today: setup.today)

        model.state.fields.shelfQuery = "カフェ"
        model.state.presented.shelf.show(.editing)
        model.state.fields.templateType = .income
        model.state.closeShelf()

        #expect(model.state.fields.shelfQuery.isEmpty)
        #expect(model.state.presented.shelf.current == nil)
        #expect(model.state.fields.templateType == .income)
    }

    @Test
    func glowsCustomizedItemAfterClosingSheet() async throws {
        let setup = try await Setup()
        let model = HomeModel(parts: .system(setup.database), today: setup.today)

        model.state.finishCustomizing()
        let untouched = model.state.presented.glow.current

        model.state.customize(.theme)
        model.state.customize(.launchScreen)
        let pending = model.state.presented.glow.current

        model.state.finishCustomizing()

        #expect(untouched == nil)
        #expect(pending == nil)
        #expect(model.state.presented.glow.current == .launchScreen)
        #expect(model.state.presented.customized == nil)
    }
}
