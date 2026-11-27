import Core
import FeatureModels
import Testing

struct MonthCursorTests {
    @Test
    func movesByMonthsAndKeepsDirection() throws {
        let october = try #require(YearMonth(year: 2026, month: 10))
        var cursor = RecordsModel.MonthCursor(month: october)

        cursor.head(forward: false)
        cursor.move(by: -2)

        #expect(cursor.month == YearMonth(year: 2026, month: 8))
        #expect(!cursor.isMovingForward)
    }

    @Test
    func showsGivenMonth() throws {
        let october = try #require(YearMonth(year: 2026, month: 10))
        let december = try #require(YearMonth(year: 2025, month: 12))
        var cursor = RecordsModel.MonthCursor(month: october)

        cursor.show(december)

        #expect(cursor.month == december)
        #expect(cursor.isMovingForward)
    }
}
