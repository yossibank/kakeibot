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

    @Test(arguments: try todayCases)
    func convertsInstantInTimeZone(fixture: TodayCase) throws {
        let timeZone = try #require(TimeZone(identifier: fixture.timeZone))

        let date = LocalDate(fixture.instant, in: timeZone)

        #expect(date == fixture.date)
    }

    @Test(arguments: try weekCases)
    func findsWeek(fixture: WeekCase) {
        let week = fixture.date.week(startingOn: fixture.weekStart)

        #expect(week == fixture.start...fixture.end)
    }

    @Test
    func encodesAsText() throws {
        let date = try #require(LocalDate("2026-02-01"))

        let data = try JSONEncoder().encode([date])
        let decoded = try JSONDecoder().decode([LocalDate].self, from: data)

        #expect(String(decoding: data, as: UTF8.self) == #"["2026-02-01"]"#)
        #expect(decoded == [date])
    }
}

extension LocalDateTests {
    struct TodayCase: Decodable, Sendable {
        let instant: Date
        let timeZone: String
        let date: LocalDate
    }

    struct WeekCase: Decodable, Sendable {
        let weekStart: Weekday
        let date: LocalDate
        let start: LocalDate
        let end: LocalDate
    }
}

private extension LocalDateTests {
    static var validity: ValidityFixture {
        get throws {
            try Fixture.load("date/local-date.json")
        }
    }

    static var todayCases: [TodayCase] {
        get throws {
            try Fixture.load("date/today.json")
        }
    }

    static var weekCases: [WeekCase] {
        get throws {
            try Fixture.load("date/week.json")
        }
    }
}
