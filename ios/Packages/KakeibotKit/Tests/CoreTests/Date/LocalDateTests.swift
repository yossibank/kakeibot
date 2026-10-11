import Core
import Foundation
import Testing

struct LocalDateTests {
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

    @Test(arguments: try Fixture.load("date/local-date.json", as: ValidityFixture.self).valid)
    func parsesValidText(text: String) throws {
        let date = try #require(LocalDate(text))
        #expect(date.description == text)
    }

    @Test(arguments: try Fixture.load("date/local-date.json", as: ValidityFixture.self).invalid)
    func rejectsInvalidText(text: String) {
        #expect(LocalDate(text) == nil)
    }

    @Test(arguments: try Fixture.load("date/today.json", as: [TodayCase].self))
    func convertsInstantInTimeZone(fixture: TodayCase) throws {
        let timeZone = try #require(TimeZone(identifier: fixture.timeZone))
        #expect(LocalDate(fixture.instant, in: timeZone) == fixture.date)
    }

    @Test(arguments: try Fixture.load("date/week.json", as: [WeekCase].self))
    func findsWeek(fixture: WeekCase) {
        #expect(fixture.date.week(startingOn: fixture.weekStart) == fixture.start...fixture.end)
    }

    @Test
    func encodesAsText() throws {
        let date = try #require(LocalDate("2026-02-01"))
        let data = try JSONEncoder().encode([date])
        #expect(String(decoding: data, as: UTF8.self) == #"["2026-02-01"]"#)
        #expect(try JSONDecoder().decode([LocalDate].self, from: data) == [date])
    }
}
