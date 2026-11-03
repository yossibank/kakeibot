@testable import AppFeature
import Core
import Foundation
import Notifications
import Store
import Synchronization
import Testing

extension AppModelTests {
    @Test
    func recordsRecurringOfNewDayWhenDateChanges() async throws {
        let database = try AppDatabase.inMemory()
        let now = Date()
        let first = try #require(LocalDate("2026-10-14"))
        let next = first.adding(days: 1)
        let clock = DayClock(first)
        let client = NotificationSchedulerTests.FakeCenter(pending: [])
        let scheduler = NotificationScheduler(client: client)
        try database.insertDefaultsIfEmpty(at: now)
        try await database.setSetting(.onboardingCompleted, to: true)
        let options = try await database.entryOptions()

        let recurring = Recurring(
            type: .expense,
            amount: 78000,
            categoryId: options.expenseCategories[0].id,
            walletId: options.wallets[0].id,
            frequency: .monthly,
            day: next.day,
            startDate: first,
            createdAt: now,
            updatedAt: now
        )

        try await database.writer.write { db in
            try recurring.insert(db)
        }

        let model = AppModel(
            openDatabase: { database },
            scheduler: scheduler,
            currentDay: clock.read
        )

        await model.open()
        let before = try database.snapshot().entries

        clock.set(next)
        await model.refreshDay()
        let after = try database.snapshot().entries

        #expect(before.isEmpty)
        #expect(model.today == next)
        #expect(after.map(\.recurringDate) == [next])
    }

    @Test
    func reschedulesNotificationsWhenDateChanges() async throws {
        let database = try AppDatabase.inMemory()
        let first = AppModel.deviceDay()
        let next = first.adding(days: 1)
        let lastReminder = next.adding(days: NotificationPlan.reminderDays - 1)
        let lastIdentifier = "\(NotificationScheduler.prefix)reminder|\(lastReminder)|"
        let clock = DayClock(first)
        let client = NotificationSchedulerTests.FakeCenter(pending: [])
        let scheduler = NotificationScheduler(client: client)
        try await database.setSetting(.onboardingCompleted, to: true)
        try await database.setSetting(.reminderTime, to: .evening)

        let model = AppModel(
            openDatabase: { database },
            scheduler: scheduler,
            currentDay: clock.read
        )

        await model.open()
        clock.set(next)
        await model.refreshDay()
        let added = await client.state.added

        #expect(added.contains { $0.hasPrefix(lastIdentifier) })
    }

    @Test
    func movesTodayEvenBeforeOpening() async throws {
        let first = try #require(LocalDate("2026-10-14"))
        let clock = DayClock(first)
        let model = AppModel(openDatabase: AppDatabase.inMemory, currentDay: clock.read)

        clock.set(first.adding(days: 1))
        await model.refreshDay()

        #expect(model.today == first.adding(days: 1))
        #expect(model.hasDatabase == false)
    }
}

extension AppModelTests {
    final class DayClock: Sendable {
        let day: Mutex<LocalDate>

        init(_ day: LocalDate) {
            self.day = Mutex(day)
        }
    }
}

extension AppModelTests.DayClock {
    func read() -> LocalDate {
        day.withLock { $0 }
    }

    func set(_ newDay: LocalDate) {
        day.withLock { $0 = newDay }
    }
}
