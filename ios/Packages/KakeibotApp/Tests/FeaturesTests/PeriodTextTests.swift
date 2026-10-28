import Core
@testable import Features
import Testing

struct PeriodTextTests {
    @Test(arguments: [
        ("2026-03-05", "3/5"),
        ("2025-03-05", "2025/3/5"),
        ("2027-01-02", "2027/1/2")
    ])
    func showsYearOnlyOutsideThisYear(text: String, expected: String) throws {
        let today = try #require(LocalDate("2026-10-17"))
        let date = try #require(LocalDate(text))

        let day = PeriodText.day(date, today: today)

        #expect(day == expected)
    }

    @Test(arguments: [
        ("2026-09-25", "2026-10-24", "9/25〜10/24"),
        ("2025-12-29", "2026-01-04", "2025/12/29〜1/4"),
        ("2025-03-01", "2025-03-31", "2025/3/1〜2025/3/31")
    ])
    func showsYearOfRangeOutsideThisYear(
        lower: String,
        upper: String,
        expected: String
    ) throws {
        let today = try #require(LocalDate("2026-10-17"))
        let lowerBound = try #require(LocalDate(lower))
        let upperBound = try #require(LocalDate(upper))

        let range = PeriodText.range(lowerBound...upperBound, today: today)

        #expect(range == expected)
    }
}
