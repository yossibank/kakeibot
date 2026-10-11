import Core
import Testing

struct MonthStartDayTests {
    @Test(arguments: try validity.valid)
    func acceptsDayInRange(day: Int) throws {
        let startDay = try #require(MonthStartDay(day))

        #expect(startDay.day == day)
    }

    @Test(arguments: try validity.invalid)
    func rejectsDayOutOfRange(day: Int) {
        let startDay = MonthStartDay(day)

        #expect(startDay == nil)
    }
}

private extension MonthStartDayTests {
    static var validity: ValidityFixture<Int> {
        get throws {
            try Fixture.load("date/month-start-day.json")
        }
    }
}
