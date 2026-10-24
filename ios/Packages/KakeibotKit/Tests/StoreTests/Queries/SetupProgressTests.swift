import Core
import Foundation
import Store
import Testing

struct SetupProgressTests {
    @Test
    func followsBudgetReminderAndTheme() async throws {
        let database = try AppDatabase.inMemory()
        let now = Date(timeIntervalSince1970: 1_791_000_000)
        try database.insertDefaultsIfEmpty(at: now)
        let month = try #require(YearMonth("2026-10"))
        let empty = try await database.firstSetupProgress()

        try await database.setBudget(80000, for: nil, from: month)
        try await database.setSetting(.reminderTime, to: ReminderTime("21:00"))
        try await database.setSetting(.theme, to: .preset(.sky))
        let filled = try await database.firstSetupProgress()

        #expect(!empty.hasBudget)
        #expect(!empty.hasWalletBalance)
        #expect(!empty.hasRecurring)
        #expect(!empty.hasReminder)
        #expect(!empty.hasTheme)
        #expect(filled.hasBudget)
        #expect(filled.hasReminder)
        #expect(filled.hasTheme)
    }
}

private extension AppDatabase {
    func firstSetupProgress() async throws -> SetupProgress {
        for try await progress in setupProgressUpdates() {
            return progress
        }

        throw CancellationError()
    }
}
