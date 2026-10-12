import Core
import Testing

struct HolidayTests {
    @Test(arguments: try cases)
    func marksHolidaysOfYear(fixture: YearCase) throws {
        let first = try #require(LocalDate(year: fixture.year, month: 1, day: 1))
        let days = (0..<365).map { first.adding(days: $0) }

        let holidays = days.filter(Holiday.contains)

        #expect(holidays == fixture.holidays)
    }

    @Test
    func skipsUnsupportedYears() throws {
        let date = try #require(LocalDate("2021-01-01"))
        #expect(Holiday.contains(date) == false)
    }
}

extension HolidayTests {
    struct YearCase: Decodable, Sendable {
        let year: Int
        let holidays: [LocalDate]
    }
}

private extension HolidayTests {
    static var cases: [YearCase] {
        get throws {
            try Fixture.load("date/holiday-dates.json")
        }
    }
}
