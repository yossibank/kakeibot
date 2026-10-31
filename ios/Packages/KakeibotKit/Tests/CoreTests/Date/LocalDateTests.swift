import Core
import Foundation
import Testing

struct LocalDateTests {
    @Test(arguments: try validity.valid)
    func parsesValidText(text: String) throws {
        let date = try #require(LocalDate(text))
        #expect(date.description == text)
    }

    @Test(arguments: try validity.invalid)
    func rejectsInvalidText(text: String) {
        let date = LocalDate(text)
        #expect(date == nil)
    }

    @Test(arguments: try instantCases)
    func convertsInstantInTimeZone(fixture: InstantCase) throws {
        let timeZone = try #require(TimeZone(identifier: fixture.timeZone))
        let date = LocalDate(fixture.instant, in: timeZone)
        #expect(date == fixture.date)
    }

    @Test(arguments: try instantCases)
    func findsStartOfDayInTimeZone(fixture: InstantCase) throws {
        let timeZone = try #require(TimeZone(identifier: fixture.timeZone))

        let start = fixture.date.startOfDay(in: timeZone)
        let justBefore = start.addingTimeInterval(-1)
        let previousDay = fixture.date.adding(days: -1)
        let startDate = LocalDate(start, in: timeZone)
        let justBeforeDate = LocalDate(justBefore, in: timeZone)

        #expect(startDate == fixture.date)
        #expect(justBeforeDate == previousDay)
    }

    @Test(arguments: try weekCases)
    func findsWeek(fixture: WeekCase) {
        let week = fixture.date.week(startingOn: fixture.weekStart)
        #expect(week == fixture.start...fixture.end)
    }

    @Test(arguments: try periodCases)
    func findsPeriodMonth(fixture: PeriodCase) {
        let startDay = fixture.monthStartDay.shifted(by: fixture.monthStartShift ?? .none)
        let dayBefore = fixture.start.adding(days: -1)
        let dayAfter = fixture.end.adding(days: 1)

        let startMonth = fixture.start.periodMonth(startingOn: startDay)
        let endMonth = fixture.end.periodMonth(startingOn: startDay)
        let dayBeforeMonth = dayBefore.periodMonth(startingOn: startDay)
        let dayAfterMonth = dayAfter.periodMonth(startingOn: startDay)

        #expect(startMonth == fixture.month)
        #expect(endMonth == fixture.month)
        #expect(dayBeforeMonth == fixture.month.adding(months: -1))
        #expect(dayAfterMonth == fixture.month.adding(months: 1))
    }

    @Test
    func movesBeforeYearOne() throws {
        let date = try #require(LocalDate("0001-01-01"))
        let dayBefore = LocalDate(year: 0, month: 12, day: 31)

        let earlier = date.adding(days: -1)

        #expect(earlier == dayBefore)
        #expect(earlier.adding(days: 1) == date)
    }

    @Test
    func encodesAsText() throws {
        let date = try #require(LocalDate("2026-02-01"))

        let data = try JSONEncoder().encode([date])
        let decoded = try JSONDecoder().decode([LocalDate].self, from: data)
        let text = String(decoding: data, as: UTF8.self)

        #expect(text == #"["2026-02-01"]"#)
        #expect(decoded == [date])
    }
}

extension LocalDateTests {
    struct InstantCase: Decodable, Sendable {
        let instant: Date
        let timeZone: String
        let date: LocalDate
    }

    struct PeriodCase: Decodable, Sendable {
        let monthStartDay: MonthStartDay
        let monthStartShift: HolidayShift?
        let month: YearMonth
        let start: LocalDate
        let end: LocalDate
    }

    struct WeekCase: Decodable, Sendable {
        let weekStart: Weekday
        let date: LocalDate
        let start: LocalDate
        let end: LocalDate
    }
}

private extension LocalDateTests {
    static var validity: ValidityFixture<String> {
        get throws {
            try Fixture.load("date/local-date-text.json")
        }
    }

    static var instantCases: [InstantCase] {
        get throws {
            try Fixture.cases("date/local-date-instant.json")
        }
    }

    static var periodCases: [PeriodCase] {
        get throws {
            try Fixture.cases("date/year-month-period.json")
        }
    }

    static var weekCases: [WeekCase] {
        get throws {
            try Fixture.cases("date/local-date-week.json")
        }
    }
}
