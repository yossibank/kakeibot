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
    func savesWeekStart() async throws {
        let database = try AppDatabase.inMemory()
        var updates = database.weekStartUpdates().makeAsyncIterator()

        let initial = try await updates.next()
        try await database.setWeekStart(.monday)
        let changed = try await updates.next()
        let saved = try await database.weekStart()

        #expect(initial == .sunday)
        #expect(changed == .monday)
        #expect(saved == .monday)
    }

    @Test
    func savesAndClearsReminderTime() async throws {
        let database = try AppDatabase.inMemory()
        let time = try #require(ReminderTime("21:30"))

        let initial = try await database.reminderTime()
        try await database.setReminderTime(time)
        let saved = try await database.reminderTime()
        try await database.setReminderTime(nil)
        let cleared = try await database.reminderTime()

        #expect(initial == nil)
        #expect(saved == time)
        #expect(cleared == nil)
    }

    @Test
    func announcesReminderTime() async throws {
        let database = try AppDatabase.inMemory()
        let time = try #require(ReminderTime("20:00"))
        var updates = database.reminderTimeUpdates().makeAsyncIterator()

        let initial = try await updates.next()
        try await database.setReminderTime(time)
        let changed = try await updates.next()

        #expect(initial == .some(nil))
        #expect(changed == time)
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

    @Test
    func savesTemplateOrder() async throws {
        let database = try AppDatabase.inMemory()

        let initial = try await database.templateOrder()
        try await database.setTemplateOrder(.frequent)
        let saved = try await database.templateOrder()

        #expect(initial == .manual)
        #expect(saved == .frequent)
    }

    @Test
    func savesRecordsLayout() async throws {
        let database = try AppDatabase.inMemory()

        let initial = try await database.recordsLayout()
        try await database.setRecordsLayout(.calendar)
        let saved = try await database.recordsLayout()

        #expect(initial == .list)
        #expect(saved == .calendar)
    }

    @Test
    func savesReviewSelection() async throws {
        let database = try AppDatabase.inMemory()

        let initialScale = try await database.reviewScale()
        let initialKind = try await database.reviewKind()
        try await database.setReviewScale(.year)
        try await database.setReviewKind(.balance)
        let scale = try await database.reviewScale()
        let kind = try await database.reviewKind()

        #expect(initialScale == .month)
        #expect(initialKind == .expense)
        #expect(scale == .year)
        #expect(kind == .balance)
    }

    @Test
    func savesCategoryMenuOpened() async throws {
        let database = try AppDatabase.inMemory()

        let before = try await database.hasOpenedCategoryMenu()
        try await database.markCategoryMenuOpened()
        let after = try await database.hasOpenedCategoryMenu()

        #expect(!before)
        #expect(after)
    }
}
