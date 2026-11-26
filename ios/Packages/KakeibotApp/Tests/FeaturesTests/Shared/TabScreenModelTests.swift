import Core
@testable import FeatureModels
import Testing

@MainActor
struct TabScreenModelTests {
    @Test
    func setsTodayOnTabModels() throws {
        let parts = try #require(ScreenParts.preview())
        let today = try #require(LocalDate("2026-10-17"))
        let next = today.adding(days: 1)
        let home = HomeModel(parts: parts, today: today)
        let records = RecordsModel(parts: parts, today: today)
        let review = ReviewModel(parts: parts, today: today)
        let assets = AssetsModel(parts: parts, today: today)

        home.setToday(next)
        records.setToday(next)
        review.setToday(next)
        assets.setToday(next)

        #expect(home.state.today == next)
        #expect(records.state.today == next)
        #expect(review.state.today == next)
        #expect(assets.input.latest.today == next)
    }

    @Test
    func failsLoadOnlyForListTabs() throws {
        let parts = try #require(ScreenParts.preview())
        let today = try #require(LocalDate("2026-10-17"))
        let home = HomeModel(parts: parts, today: today)
        let records = RecordsModel(parts: parts, today: today)
        let review = ReviewModel(parts: parts, today: today)
        let assets = AssetsModel(parts: parts, today: today)
        let wasFailed = records.isLoadFailed

        home.input.list = .failed
        records.input.list = .failed
        review.input.list = .failed
        assets.input.list = .failed

        #expect(!wasFailed)
        #expect(!home.isLoadFailed)
        #expect(records.isLoadFailed)
        #expect(review.isLoadFailed)
        #expect(assets.isLoadFailed)
    }
}
