import Core
import Foundation
import Testing

struct YearMonthTests {
    @Test(arguments: try validity.valid)
    func parsesValidText(text: String) throws {
        let month = try #require(YearMonth(text))
        #expect(month.description == text)
    }

    @Test(arguments: try validity.invalid)
    func rejectsInvalidText(text: String) {
        #expect(YearMonth(text) == nil)
    }

    @Test(arguments: try periodCases)
    func findsPeriodOfMonth(fixture: PeriodCase) {
        let period = fixture.month.period(monthStartDay: fixture.monthStartDay)
        #expect(period == fixture.start...fixture.end)
    }

    @Test(arguments: try periodCases)
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

extension YearMonthTests {
    struct PeriodCase: Decodable, Sendable {
        let monthStartDay: Int
        let month: YearMonth
        let start: LocalDate
        let end: LocalDate
    }
}

private extension YearMonthTests {
    static var validity: ValidityFixture {
        get throws {
            try Fixture.load("date/year-month.json")
        }
    }

    static var periodCases: [PeriodCase] {
        get throws {
            try Fixture.load("date/period.json")
        }
    }
}
