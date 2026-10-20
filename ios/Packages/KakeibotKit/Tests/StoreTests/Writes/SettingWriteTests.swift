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

        let initial = try await database.setting(.monthStartDay)
        try await database.setSetting(.monthStartDay, to: payday)
        let saved = try await database.setting(.monthStartDay)
        try await database.setSetting(.monthStartDay, to: last)
        let changed = try await database.setting(.monthStartDay)

        #expect(initial == .first)
        #expect(saved == payday)
        #expect(changed.isLastDay)
    }

    @Test
    func savesKeypadChoice() async throws {
        let database = try AppDatabase.inMemory()

        let initial = try await database.setting(.entryOpensKeypad)
        try await database.setSetting(.entryOpensKeypad, to: false)
        let saved = try await database.setting(.entryOpensKeypad)

        #expect(initial)
        #expect(!saved)
    }

    @Test
    func savesClosedHints() async throws {
        let database = try AppDatabase.inMemory()

        let initial = try await database.setting(.closedHints)
        try await database.setSetting(.closedHints, to: [.wallets, .budgets])
        let saved = try await database.setting(.closedHints)
        let text = try await database.writer.read { db in
            try String.fetchOne(
                db,
                sql: "SELECT value FROM setting WHERE key = 'closed_hints'"
            )
        }

        #expect(initial.isEmpty)
        #expect(saved == [.wallets, .budgets])
        #expect(text == "budgets,wallets")
    }

    @Test
    func announcesMonthStartDay() async throws {
        let database = try AppDatabase.inMemory()
        let payday = try #require(MonthStartDay(25))
        var updates = database.settingUpdates(.monthStartDay)
            .makeAsyncIterator()

        let initial = try await updates.next()
        try await database.setSetting(.monthStartDay, to: payday)
        let changed = try await updates.next()

        #expect(initial == .first)
        #expect(changed == payday)
    }

    @Test
    func savesWeekStart() async throws {
        let database = try AppDatabase.inMemory()
        var updates = database.settingUpdates(.weekStart).makeAsyncIterator()

        let initial = try await updates.next()
        try await database.setSetting(.weekStart, to: .monday)
        let changed = try await updates.next()
        let saved = try await database.setting(.weekStart)

        #expect(initial == .sunday)
        #expect(changed == .monday)
        #expect(saved == .monday)
    }

    @Test
    func savesAndClearsReminderTime() async throws {
        let database = try AppDatabase.inMemory()
        let time = try #require(ReminderTime("21:30"))

        let initial = try await database.setting(.reminderTime)
        try await database.setSetting(.reminderTime, to: time)
        let saved = try await database.setting(.reminderTime)
        try await database.setSetting(.reminderTime, to: nil)
        let cleared = try await database.setting(.reminderTime)

        #expect(initial == nil)
        #expect(saved == time)
        #expect(cleared == nil)
    }

    @Test
    func announcesReminderTime() async throws {
        let database = try AppDatabase.inMemory()
        let time = try #require(ReminderTime("20:00"))
        var updates = database.settingUpdates(.reminderTime).makeAsyncIterator()

        let initial = try await updates.next()
        try await database.setSetting(.reminderTime, to: time)
        let changed = try await updates.next()

        #expect(initial == .some(nil))
        #expect(changed == time)
    }

    @Test
    func completesOnboarding() async throws {
        let database = try AppDatabase.inMemory()

        let before = try await database.setting(.onboardingCompleted)
        try await database.setSetting(.onboardingCompleted, to: true)
        let after = try await database.setting(.onboardingCompleted)

        #expect(!before)
        #expect(after)
    }

    @Test
    func savesLaunchScreen() async throws {
        let database = try AppDatabase.inMemory()

        let initial = try await database.setting(.launchScreen)
        try await database.setSetting(.launchScreen, to: .entry)
        let saved = try await database.setting(.launchScreen)

        #expect(initial == .home)
        #expect(saved == .entry)
    }

    @Test
    func savesTemplateOrder() async throws {
        let database = try AppDatabase.inMemory()

        let initial = try await database.setting(.templateOrder)
        try await database.setSetting(.templateOrder, to: .frequent)
        let saved = try await database.setting(.templateOrder)

        #expect(initial == .manual)
        #expect(saved == .frequent)
    }

    @Test
    func savesRecordsLayout() async throws {
        let database = try AppDatabase.inMemory()

        let initial = try await database.setting(.recordsLayout)
        try await database.setSetting(.recordsLayout, to: .calendar)
        let saved = try await database.setting(.recordsLayout)

        #expect(initial == .list)
        #expect(saved == .calendar)
    }

    @Test
    func savesReviewSelection() async throws {
        let database = try AppDatabase.inMemory()

        let initialScale = try await database.setting(.reviewScale)
        let initialKind = try await database.setting(.reviewKind)
        try await database.setSetting(.reviewScale, to: .year)
        try await database.setSetting(.reviewKind, to: .balance)
        let scale = try await database.setting(.reviewScale)
        let kind = try await database.setting(.reviewKind)

        #expect(initialScale == .month)
        #expect(initialKind == .expense)
        #expect(scale == .year)
        #expect(kind == .balance)
    }

    @Test
    func savesCategoryMenuOpened() async throws {
        let database = try AppDatabase.inMemory()

        let before = try await database.setting(.categoryMenuOpened)
        try await database.setSetting(.categoryMenuOpened, to: true)
        let after = try await database.setting(.categoryMenuOpened)

        #expect(!before)
        #expect(after)
    }
}
