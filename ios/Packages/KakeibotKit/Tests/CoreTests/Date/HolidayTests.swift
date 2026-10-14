import Core
import Testing

struct HolidayTests {
    @Test(arguments: try cases)
    func namesHolidaysOfYear(fixture: YearCase) throws {
        let newYear = LocalDate(year: fixture.year, month: 1, day: 1)
        let first = try #require(newYear)
        let days = (0..<365).map { first.adding(days: $0) }

        let holidays = days.compactMap { date in
            Holiday.name(of: date).map { NamedDate(date: date, name: $0) }
        }

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
        let holidays: [NamedDate]
    }

    struct NamedDate: Decodable, Equatable, Sendable {
        let date: LocalDate
        let name: String
    }
}

private extension HolidayTests {
    static var cases: [YearCase] {
        get throws {
            try Fixture.load("date/holiday-dates.json")
        }
    }
}
