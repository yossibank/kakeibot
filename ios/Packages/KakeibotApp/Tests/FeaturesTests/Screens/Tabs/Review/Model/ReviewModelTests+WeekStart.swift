import Core
import FeatureModels
import Features
import Testing

extension ReviewModelTests {
    @Test
    func startsWeekOnSundayBeforeSettingArrives() async throws {
        let setup = try await RecordsModelTests.Setup()
        let model = ReviewModel(parts: .system(setup.database), today: setup.today)

        model.setScale(.week)

        #expect(model.input.weekStart == .sunday)
        #expect(model.output.period.range.lowerBound.description == "2026-10-11")
    }
}
