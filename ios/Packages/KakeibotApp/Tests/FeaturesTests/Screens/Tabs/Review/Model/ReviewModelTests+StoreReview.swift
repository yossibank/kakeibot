@testable import Features
import Store
import Testing
import TestSupport

extension ReviewModelTests {
    @Test
    func showsStoreReviewCardAfterTenEntries() async throws {
        let setup = try await RecordsModelTests.Setup()
        let model = ReviewModel(database: setup.database, clock: .system, today: setup.today)

        for _ in 0..<9 {
            try await setup.save(.expense, amount: 980, on: "2026-10-12")
        }

        await model.refreshStoreReviewCard()
        let before = model.state.showsStoreReviewCard

        try await setup.save(.expense, amount: 980, on: "2026-10-12")
        await model.refreshStoreReviewCard()
        let after = model.state.showsStoreReviewCard

        #expect(!before)
        #expect(after)
    }

    @Test
    func hidesStoreReviewCardAfterClosing() async throws {
        let setup = try await RecordsModelTests.Setup()
        let model = ReviewModel(database: setup.database, clock: .system, today: setup.today)

        for _ in 0..<10 {
            try await setup.save(.expense, amount: 980, on: "2026-10-12")
        }

        await model.refreshStoreReviewCard()
        await model.closeStoreReviewCard()
        await model.refreshStoreReviewCard()
        let shows = model.state.showsStoreReviewCard
        let closed = try await setup.database.setting(.storeReviewCardClosed)

        #expect(!shows)
        #expect(closed)
    }

    @Test
    func marksStoreReviewOpened() async throws {
        let setup = try await RecordsModelTests.Setup()
        let model = ReviewModel(database: setup.database, clock: .system, today: setup.today)

        await model.openStoreReview()
        let closed = try await setup.database.setting(.storeReviewCardClosed)
        let opened = try await setup.database.setting(.storeReviewOpened)

        #expect(closed)
        #expect(opened)
    }

    @Test
    func keepsStoreReviewUnopenedAfterClosing() async throws {
        let setup = try await RecordsModelTests.Setup()
        let model = ReviewModel(database: setup.database, clock: .system, today: setup.today)

        await model.closeStoreReviewCard()
        let opened = try await setup.database.setting(.storeReviewOpened)

        #expect(!opened)
    }
}
