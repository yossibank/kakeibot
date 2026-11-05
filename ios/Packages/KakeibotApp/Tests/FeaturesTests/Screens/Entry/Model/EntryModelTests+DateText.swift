import Core
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

    @Test(arguments: [
        ("2026-10-12", "今日 10/12（月）"),
        ("2026-10-11", "昨日 10/11（日）"),
        ("2026-10-05", "10/5（月）"),
        ("2025-12-31", "2025/12/31（水）")
    ])
    func describesDate(text: String, expected: String) throws {
        let today = try #require(LocalDate("2026-10-12"))
        let date = try #require(LocalDate(text))
        let description = EntryModel.dateText(for: date, today: today)
        #expect(description == expected)
    }

    @Test(arguments: [
        ("2026-10-12", "今日"),
        ("2026-10-11", "昨日"),
        ("2026-10-05", "10/5"),
        ("2025-12-31", "2025/12/31")
    ])
    func shortensDate(text: String, expected: String) throws {
        let today = try #require(LocalDate("2026-10-12"))
        let date = try #require(LocalDate(text))
        let description = EntryModel.shortDateText(for: date, today: today)
        #expect(description == expected)
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
        model.date = try #require(LocalDate(text))
        let quick = model.quickDate(today: today)
        #expect(quick == LocalDate(expected))
    }
}
