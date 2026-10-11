import Core
import Foundation
import Testing

struct YearMonthTests {
    struct PeriodCase: Decodable, Sendable {
        let monthStartDay: Int
        let month: YearMonth
        let start: LocalDate
        let end: LocalDate
    }

    @Test(arguments: try Fixture.load("date/year-month.json", as: ValidityFixture.self).valid)
    func parsesValidText(text: String) throws {
        let month = try #require(YearMonth(text))
        #expect(month.description == text)
    }

    @Test(arguments: try Fixture.load("date/year-month.json", as: ValidityFixture.self).invalid)
    func rejectsInvalidText(text: String) {
        #expect(YearMonth(text) == nil)
    }

    @Test(arguments: try Fixture.load("date/period.json", as: [PeriodCase].self))
    func findsPeriodOfMonth(fixture: PeriodCase) {
        let period = fixture.month.period(monthStartDay: fixture.monthStartDay)
        #expect(period == fixture.start...fixture.end)
    }

    @Test(arguments: try Fixture.load("date/period.json", as: [PeriodCase].self))
    func namesPeriodByMonth(fixture: PeriodCase) {
        let day = fixture.monthStartDay
        #expect(fixture.start.periodMonth(monthStartDay: day) == fixture.month)
        #expect(fixture.end.periodMonth(monthStartDay: day) == fixture.month)
        #expect(
            fixture.start.adding(days: -1).periodMonth(monthStartDay: day)
                == fixture.month.adding(months: -1)
        )
        #expect(
            fixture.end.adding(days: 1).periodMonth(monthStartDay: day)
                == fixture.month.adding(months: 1)
        )
    }
}
