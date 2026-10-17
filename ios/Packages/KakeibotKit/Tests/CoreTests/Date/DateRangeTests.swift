import Core
import Testing

struct DateRangeTests {
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
        #expect(days.first == fixture.start)
        #expect(days.last == fixture.end)
        #expect(pairs.allSatisfy { $0.adding(days: 1) == $1 })
    }
}

extension DateRangeTests {
    struct WeeksCase: Decodable, Sendable {
        let weekStart: Weekday
        let start: LocalDate
        let end: LocalDate
        let leading: Int
        let trailing: Int
        let rows: Int
    }
}

private extension DateRangeTests {
    static var weeksCases: [WeeksCase] {
        get throws {
            try Fixture.load("date/date-range-weeks.json")
        }
    }
}
