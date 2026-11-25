import Core
@testable import FeatureModels
@testable import Features
import Testing

struct PeriodTextTests {
    @Test(arguments: try dayCases)
    func showsYearOnlyOutsideThisYear(fixture: DayCase) {
        let day = PeriodText.day(fixture.date, today: fixture.today)
        #expect(day == fixture.text)
    }

    @Test(arguments: try rangeCases)
    func showsYearOfRangeOutsideThisYear(fixture: RangeCase) {
        let range = PeriodText.range(fixture.lower...fixture.upper, today: fixture.today)
        #expect(range == fixture.text)
    }
}

extension PeriodTextTests {
    struct DayCase: Decodable, Sendable {
        let summary: String
        let today: LocalDate
        let date: LocalDate
        let text: String
    }

    struct RangeCase: Decodable, Sendable {
        let summary: String
        let today: LocalDate
        let lower: LocalDate
        let upper: LocalDate
        let text: String
    }

    static var dayCases: [DayCase] {
        get throws {
            try FeaturesFixture.cases("date/period-text-day.json")
        }
    }

    static var rangeCases: [RangeCase] {
        get throws {
            try FeaturesFixture.cases("date/period-text-range.json")
        }
    }
}
