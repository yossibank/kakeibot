import Core
import Foundation
import Store
import Testing

struct SettingWriteTests {
    @Test
    func savesMonthStartDay() async throws {
        let database = try AppDatabase.inMemory()
        let payday = try #require(MonthStartDay(25))
        let last = try #require(MonthStartDay(31))

        let initial = try await database.monthStartDay()
        try await database.setMonthStartDay(payday)
        let saved = try await database.monthStartDay()
        try await database.setMonthStartDay(last)
        let changed = try await database.monthStartDay()

        #expect(initial == .first)
        #expect(saved == payday)
        #expect(changed.isLastDay)
    }

    @Test
    func announcesMonthStartDay() async throws {
        let database = try AppDatabase.inMemory()
        let payday = try #require(MonthStartDay(25))
        var updates = database.monthStartDayUpdates().makeAsyncIterator()

        let initial = try await updates.next()
        try await database.setMonthStartDay(payday)
        let changed = try await updates.next()

        #expect(initial == .first)
        #expect(changed == payday)
    }

    @Test
    func completesOnboarding() async throws {
        let database = try AppDatabase.inMemory()

        let before = try await database.isOnboardingCompleted()
        try await database.completeOnboarding()
        let after = try await database.isOnboardingCompleted()

        #expect(!before)
        #expect(after)
    }

    @Test
    func savesLaunchScreen() async throws {
        let database = try AppDatabase.inMemory()

        let initial = try await database.launchScreen()
        try await database.setLaunchScreen(.entry)
        let saved = try await database.launchScreen()

        #expect(initial == .home)
        #expect(saved == .entry)
    }
}
