import Core
import Testing

struct ReviewPaceTests {
    @Test
    func countsPaceInTheMiddleOfMonth() throws {
        let pace = try Self.pace(spent: 98400)

        #expect(pace.elapsedDays == 21)
        #expect(pace.daysLeft == 10)
        #expect(pace.expected == 105_000)
        #expect(pace.lead == 6600)
        #expect(pace.perDay == 5160)
        #expect(pace.projected == 140_571)
        #expect(pace.projectedLeft == 9429)
        #expect(pace.verdict == .onTrack)
    }

    @Test
    func turnsFastWhenSpendingAheadOfPace() throws {
        let pace = try Self.pace(spent: 120_000)

        #expect(pace.verdict == .fast)
        #expect(pace.lead == -15000)
    }

    @Test
    func turnsOverPastTheLimit() throws {
        let pace = try Self.pace(spent: 160_000)

        #expect(pace.verdict == .over)
        #expect(pace.perDay == 0)
    }

    @Test
    func clampsDaysOutsideThePeriod() throws {
        let early = try Self.pace(spent: 0, today: LocalDate("2026-10-20"))
        let late = try Self.pace(spent: 0, today: LocalDate("2026-12-05"))

        #expect(early.elapsedDays == 1)
        #expect(late.elapsedDays == 30)
        #expect(late.daysLeft == 1)
    }
}

private extension ReviewPaceTests {
    static func pace(
        spent: Int,
        today: LocalDate? = LocalDate("2026-11-21")
    ) throws -> ReviewPace {
        let start = try #require(LocalDate("2026-11-01"))
        let end = try #require(LocalDate("2026-11-30"))

        return try ReviewPace(
            limit: 150_000,
            basis: .budget,
            spent: spent,
            range: start...end,
            today: #require(today)
        )
    }
}
