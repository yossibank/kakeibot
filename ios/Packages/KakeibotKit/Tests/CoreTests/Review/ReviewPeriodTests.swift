import Core
import Testing

struct ReviewPeriodTests {
    @Test(arguments: try periodCases)
    func findsPeriodAndPrevious(fixture: PeriodCase) {
        let period = ReviewPeriod(
            scale: fixture.scale,
            containing: fixture.date,
            monthStartDay: fixture.monthStartDay,
            weekStart: fixture.weekStart
        )

        let previous = period.previous

        #expect(period.range == fixture.start...fixture.end)
        #expect(previous.range == fixture.previousStart...fixture.previousEnd)
        #expect(previous.adding(1) == period)
    }

    @Test(arguments: try periodCases)
    func movesSeveralPeriods(fixture: PeriodCase) {
        let period = ReviewPeriod(
            scale: fixture.scale,
            containing: fixture.date,
            monthStartDay: fixture.monthStartDay,
            weekStart: fixture.weekStart
        )

        let back = period.adding(-3)
        let stepped = period.previous.previous.previous

        #expect(back == stepped)
        #expect(back.adding(3) == period)
    }
}

extension ReviewPeriodTests {
    struct PeriodCase: Decodable, Sendable {
        let scale: ReviewPeriod.Scale
        let date: LocalDate
        let monthStartDay: MonthStartDay
        let weekStart: Weekday
        let start: LocalDate
        let end: LocalDate
        let previousStart: LocalDate
        let previousEnd: LocalDate
    }
}

private extension ReviewPeriodTests {
    static var periodCases: [PeriodCase] {
        get throws {
            try Fixture.load("review/review-period.json")
        }
    }
}
