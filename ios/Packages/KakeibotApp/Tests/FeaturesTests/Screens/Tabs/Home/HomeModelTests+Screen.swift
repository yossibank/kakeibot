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

        model.state.openStamp = tally
        model.state.pickStampDay(date)

        let first = model.state.takePendingDay()
        let second = model.state.takePendingDay()

        #expect(empty == nil)
        #expect(model.state.openStamp == nil)
        #expect(first == date)
        #expect(second == nil)
    }

    @Test
    func startsShelfOverAfterClosing() async throws {
        let setup = try await Setup()
        let model = HomeModel(parts: .system(setup.database), today: setup.today)

        model.state.shelf.query = "カフェ"
        model.state.shelf.isEditing = true
        model.state.templateType = .income
        model.state.closeShelf()

        #expect(model.state.shelf.query.isEmpty)
        #expect(model.state.shelf.isEditing == false)
        #expect(model.state.templateType == .income)
    }
}
