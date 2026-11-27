import Core
import FeatureModels
import Features
import Foundation
import Store
import Testing

extension ReviewModelTests {
    @Test
    func opensChosenEntryAfterClosingShareSheet() async throws {
        let setup = try await RecordsModelTests.Setup()
        try await setup.save(.expense, amount: 500, on: "2026-10-12")
        let model = ReviewModel(parts: .system(setup.database), today: setup.today)

        try await observe(model) {
            model.input.list.isLoaded
        }

        let share = try #require(model.output.categoryShares.first)
        let id = try #require(model.output.rows(for: share).first?.id)

        model.state.presented.sheet.show(.share(share))

        let empty = model.state.takePending()

        model.choose(id, in: share)

        let sheetAfterChoice = model.state.presented.sheet.current?.id
        let first = model.state.takePending()
        let second = model.state.takePending()

        #expect(empty == nil)
        #expect(sheetAfterChoice == nil)
        #expect(first == .entry(id))
        #expect(second == nil)
    }

    @Test
    func closesAnalysisAndItsShareBeforeOpening() async throws {
        let setup = try await RecordsModelTests.Setup()
        try await setup.save(.expense, amount: 500, on: "2026-10-12")
        let model = ReviewModel(parts: .system(setup.database), today: setup.today)

        try await observe(model) {
            model.input.list.isLoaded
        }

        let share = try #require(model.output.categoryShares.first)
        let id = try #require(model.output.rows(for: share).first?.id)

        model.state.presented.sheet.show(.analysis)
        model.state.presented.analysisShare.item = share

        let sheetBefore = model.state.presented.sheet.current?.id

        model.choose(id, in: share)

        #expect(sheetBefore == .analysis)
        #expect(model.state.presented.sheet.current?.id == nil)
        #expect(model.state.presented.analysisShare.current?.id == nil)
        #expect(model.state.takePending() == .entry(id))
    }

    @Test
    func opensPickedDayAfterClosingStampSheet() async throws {
        let setup = try await RecordsModelTests.Setup()
        try setup.database.insertShelfIfEmpty(at: Date())
        let shelf = try await setup.database.shelfIconList().shelfIcons
        let star = try #require(shelf.first?.iconId)
        let date = try #require(LocalDate("2026-10-05"))
        try await setup.database.stamp(star, on: date, at: Date())
        let model = ReviewModel(parts: .system(setup.database), today: setup.today)

        try await observe(model) {
            !model.output.stampTallies.isEmpty
        }

        let tally = try #require(model.output.stampTallies.first)

        model.state.presented.sheet.show(.stamp(tally))

        let sheetBefore = model.state.presented.sheet.current?.id

        model.state.open(afterSheet: .day(date))

        #expect(sheetBefore == .stamp(tally.id))
        #expect(model.state.presented.sheet.current?.id == nil)
        #expect(model.state.takePending() == .day(date))
    }
}
