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

    @Test(arguments: try weeksCases)
    func laysOutWeeks(fixture: WeeksCase) {
        let weeks = fixture.month.weeks(startingOn: fixture.weekStart)
        let cells = weeks.flatMap(\.self)
        let days = cells.compactMap(\.self)

        #expect(weeks.count == fixture.rows)
        #expect(weeks.allSatisfy { $0.count == 7 })
        #expect(cells.prefix(fixture.leading).allSatisfy { $0 == nil })
        #expect(cells.suffix(fixture.trailing).allSatisfy { $0 == nil })
        #expect(days.map(\.day) == Array(1...fixture.month.numberOfDays))
        #expect(days.allSatisfy { $0.yearMonth == fixture.month })
    }
}

extension YearMonthTests {
    struct WeeksCase: Decodable, Sendable {
        let weekStart: Weekday
        let month: YearMonth
        let leading: Int
        let trailing: Int
        let rows: Int
    }

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

    static var weeksCases: [WeeksCase] {
        get throws {
            try Fixture.load("date/year-month-weeks.json")
        }
    }

    static var validity: ValidityFixture<String> {
        get throws {
            try Fixture.load("date/year-month-text.json")
        }
    }
}
