import Core
import FeatureModels
import Features
import Testing

extension RecordsModelTests {
    @Test
    func startsWeekOnSundayBeforeSettingArrives() async throws {
        let setup = try await Setup()
        let model = RecordsModel(parts: .system(setup.database), today: setup.today)
        let firstWeek = try #require(model.output.weeks.first)

        #expect(model.input.weekStart == .sunday)
        #expect(firstWeek[4]?.description == "2026-10-01")
    }
}
