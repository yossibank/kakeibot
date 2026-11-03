import Core
import Testing

struct DateRangeWeeksTests {
    @Test(arguments: try weeksCases)
    func laysOutWeeks(fixture: WeeksCase) {
        let range = fixture.start...fixture.end
        let weeks = range.weeks(startingOn: fixture.weekStart)
        let cells = weeks.flatMap(\.self)
        let days = cells.compactMap(\.self)
        let pairs = zip(days, days.dropFirst())

        #expect(weeks.count == fixture.rows)
        #expect(weeks.allSatisfy { $0.count == 7 })
        #expect(cells.prefix(fixture.leading).allSatisfy { $0 == nil })
        #expect(cells.suffix(fixture.trailing).allSatisfy { $0 == nil })
        #expect(cells.count == fixture.leading + days.count + fixture.trailing)
        #expect(days.first == fixture.start)
        #expect(days.last == fixture.end)
        #expect(pairs.allSatisfy { $0.adding(days: 1) == $1 })
    }
}

extension DateRangeWeeksTests {
    struct WeeksCase: Decodable, Sendable {
        let weekStart: Weekday
        let start: LocalDate
        let end: LocalDate
        let leading: Int
        let trailing: Int
        let rows: Int
    }
}

private extension DateRangeWeeksTests {
    static var weeksCases: [WeeksCase] {
        get throws {
            try CoreFixture.cases("date/date-range-weeks.json")
        }
    }
}
