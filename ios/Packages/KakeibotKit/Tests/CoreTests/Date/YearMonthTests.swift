import Core
import Testing

struct YearMonthTests {
    @Test(arguments: try validity.valid)
    func parsesValidText(text: String) throws {
        let month = try #require(YearMonth(text))

        #expect(month.description == text)
    }

    @Test(arguments: try validity.invalid)
    func rejectsInvalidText(text: String) {
        let month = YearMonth(text)

        #expect(month == nil)
    }

    @Test
    func movesBeforeYearOne() throws {
        let month = try #require(YearMonth(year: 1, month: 1))

        let earlier = month.adding(months: -13)

        #expect(earlier == YearMonth(year: -1, month: 12))
        #expect(earlier.description == "-0001-12")
        #expect(YearMonth(earlier.description) == nil)
    }

    @Test(arguments: try periodCases)
    func findsPeriod(fixture: PeriodCase) {
        let period = fixture.month.period(startingOn: fixture.monthStartDay)

        #expect(period == fixture.start...fixture.end)
    }
}

extension YearMonthTests {
    struct PeriodCase: Decodable, Sendable {
        let monthStartDay: MonthStartDay
        let month: YearMonth
        let start: LocalDate
        let end: LocalDate
    }
}

private extension YearMonthTests {
    static var periodCases: [PeriodCase] {
        get throws {
            try Fixture.load("date/year-month-period.json")
        }
    }

    static var validity: ValidityFixture<String> {
        get throws {
            try Fixture.load("date/year-month-text.json")
        }
    }
}
