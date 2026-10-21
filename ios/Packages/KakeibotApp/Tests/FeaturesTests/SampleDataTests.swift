#if DEBUG
import Core
@testable import Features
import Foundation
import Store
import Testing

struct SampleDataTests {
    @Test
    func insertsMonthsOfData() async throws {
        let database = try AppDatabase.inMemory()
        let now = Date(timeIntervalSince1970: 1_791_000_000)
        try database.insertDefaultsIfEmpty(at: now)
        let today = try #require(LocalDate("2026-10-17"))

        try await SampleData.insert(into: database, today: today, now: now)
        let snapshot = try database.snapshot()
        let types = Set(snapshot.entries.map(\.type))
        let dates = snapshot.entries.map(\.date)
        let noSpendDays = Set(snapshot.noSpendDays.map(\.date))
        let start = today.adding(days: -SampleData.dayCount)

        let spentDays = Set(
            snapshot.entries.filter { $0.type == .expense }.map(\.date)
        )

        #expect(snapshot.entries.count > 250)
        #expect(types == [.expense, .income, .transfer])
        #expect(dates.allSatisfy { $0 <= today })
        #expect(dates.allSatisfy { $0 > start })
        #expect(!noSpendDays.isEmpty)
        #expect(noSpendDays.isDisjoint(with: spentDays))
        #expect(snapshot.budgets.count == 5)
        #expect(snapshot.templates.count == 4)
        #expect(snapshot.wallets.count == 5)
        #expect(snapshot.recurrings.count == 5)
        #expect(snapshot.entries.contains { $0.recurringId != nil })
    }
}
#endif
