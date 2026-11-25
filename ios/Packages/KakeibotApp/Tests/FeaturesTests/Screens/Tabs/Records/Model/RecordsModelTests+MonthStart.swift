import Core
import FeatureModels
import Features
import Store
import Testing
import TestSupport

extension RecordsModelTests {
    @Test
    func returnsToCurrentPeriodWhenMonthStartDayChanges() async throws {
        let setup = try await Setup()
        let model = RecordsModel(parts: .system(setup.database), today: setup.today)
        let startDay = try #require(MonthStartDay(25))

        let task = Task {
            await model.run()
        }

        await ObservationWait.until {
            model.input.list != nil
        }

        model.state.move(months: -3)
        let moved = model.state.month

        try await setup.database.setSetting(.monthStartDay, to: startDay)

        await ObservationWait.until {
            model.input.monthStartDay == startDay
        }

        task.cancel()

        #expect(moved == YearMonth(year: 2026, month: 7))
        #expect(model.state.month == YearMonth(year: 2026, month: 10))
        #expect(model.output.periodText == "9/25〜10/24")
    }
}
