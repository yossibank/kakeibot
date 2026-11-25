import Core
import FeatureModels
import Features
import Testing

extension EntryModelTests {
    @Test(arguments: [
        ("2026-10-12", "日付"),
        ("2026-10-11", "日付"),
        ("2026-10-10", "日付・2日前"),
        ("2026-10-14", "日付・2日後")
    ])
    func titlesDate(text: String, expected: String) throws {
        let today = try #require(LocalDate("2026-10-12"))
        let date = try #require(LocalDate(text))
        let title = EntryModel.dateTitle(for: date, today: today)
        #expect(title == expected)
    }

    @Test(arguments: try dateTextCases)
    func describesDate(fixture: DateTextCase) {
        let description = EntryModel.dateText(for: fixture.date, today: fixture.today)
        #expect(description == fixture.text)
    }

    @Test(arguments: try dateTextCases)
    func shortensDate(fixture: DateTextCase) {
        let description = EntryModel.shortDateText(for: fixture.date, today: fixture.today)
        #expect(description == fixture.short)
    }

    @Test(arguments: [
        ("2026-10-12", "今日"),
        ("2026-10-11", "10/11（日）"),
        ("2025-12-31", "2025/12/31（水）")
    ])
    func labelsKeypadDate(text: String, expected: String) throws {
        let today = try #require(LocalDate("2026-10-12"))
        let date = try #require(LocalDate(text))
        let description = EntryModel.keypadDateText(for: date, today: today)
        #expect(description == expected)
    }

    @Test(arguments: [
        ("2026-10-12", "2026-10-11"),
        ("2026-10-11", "2026-10-12"),
        ("2026-10-05", "2026-10-12")
    ])
    func switchesQuickDate(text: String, expected: String) async throws {
        let model = try await Self.newModel()
        let today = try #require(LocalDate("2026-10-12"))
        try model.state.setDate(#require(LocalDate(text)))
        let quick = model.output.quickDate(today: today)
        #expect(quick == LocalDate(expected))
    }
}

extension EntryModelTests {
    struct DateTextCase: Decodable, Sendable {
        let summary: String
        let today: LocalDate
        let date: LocalDate
        let text: String
        let short: String
    }

    nonisolated static var dateTextCases: [DateTextCase] {
        get throws {
            try FeaturesFixture.cases("entry/entry-date-text.json")
        }
    }
}
