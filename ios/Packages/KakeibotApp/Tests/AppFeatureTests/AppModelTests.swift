@testable import AppFeature
import Core
import Foundation
import Notifications
import Store
import Testing

@MainActor
struct AppModelTests {
    @Test
    func asksFirstSetupThenOpens() async {
        let model = AppModel(openDatabase: AppDatabase.inMemory)

        await model.open()

        guard case .onboarding = model.launch else {
            Issue.record("Expected onboarding, got \(model.launch)")
            return
        }

        model.finishOnboarding()

        guard case .ready = model.launch else {
            Issue.record("Expected ready, got \(model.launch)")
            return
        }
    }

    @Test
    func opensDatabaseAfterFirstSetup() async throws {
        let database = try AppDatabase.inMemory()
        try await database.setSetting(.onboardingCompleted, to: true)
        let model = AppModel { database }

        await model.open()

        guard case .ready = model.launch else {
            Issue.record("Expected ready, got \(model.launch)")
            return
        }
    }

    @Test
    func generatesRecurringEntriesOnOpen() async throws {
        let database = try AppDatabase.inMemory()
        let now = Date()
        try database.insertDefaultsIfEmpty(at: now)
        try await database.setSetting(.onboardingCompleted, to: true)
        let options = try await database.entryOptions()
        let today = LocalDate(now, in: .current)

        let recurring = Recurring(
            type: .expense,
            amount: 78000,
            categoryId: options.expenseCategories[0].id,
            walletId: options.wallets[0].id,
            frequency: .monthly,
            day: today.day,
            startDate: today,
            createdAt: now,
            updatedAt: now
        )

        try await database.writer.write { db in
            try recurring.insert(db)
        }

        let model = AppModel { database }

        await model.open()
        let entries = try database.snapshot().entries

        #expect(entries.map(\.recurringDate) == [today])
    }

    @Test
    func reschedulesNotificationsOnDemand() async throws {
        let database = try AppDatabase.inMemory()
        let client = NotificationSchedulerTests.FakeCenter(pending: [])
        let scheduler = NotificationScheduler(client: client)
        try await database.setSetting(.onboardingCompleted, to: true)
        try await database.setSetting(.reminderTime, to: .evening)
        let model = AppModel(openDatabase: { database }, scheduler: scheduler)

        await model.open()
        await model.rescheduleNotifications()

        let state = await client.state

        #expect(!state.added.isEmpty)
    }

    @Test
    func reportsFailureToOpen() async {
        let model = AppModel {
            throw AppDatabase.SetupError.appGroupUnavailable
        }

        await model.open()

        guard case .failed = model.launch else {
            Issue.record("Expected failed, got \(model.launch)")
            return
        }
    }

    @Test
    func opensAgainAfterFailure() async throws {
        let database = try AppDatabase.inMemory()
        let attempts = Attempts()

        let model = AppModel {
            attempts.count += 1

            guard attempts.count > 1 else {
                throw AppDatabase.SetupError.appGroupUnavailable
            }

            return database
        }

        await model.open()
        await model.retryOpen()

        guard case .onboarding = model.launch else {
            Issue.record("Expected onboarding, got \(model.launch)")
            return
        }

        #expect(attempts.count == 2)
    }

    @Test
    func observesThemeAfterRetryOpen() async throws {
        let database = try AppDatabase.inMemory()
        let attempts = Attempts()

        let model = AppModel {
            attempts.count += 1

            guard attempts.count > 1 else {
                throw AppDatabase.SetupError.appGroupUnavailable
            }

            return database
        }

        await model.open()
        #expect(!model.hasDatabase)

        await model.retryOpen()
        #expect(model.hasDatabase)

        let task = Task {
            await model.observeTheme()
        }

        try await database.setSetting(.theme, to: .preset(.wine))

        let expected = ThemeLook.fixed(ThemePreset.wine.palette)

        for _ in 0..<200 where model.look != expected {
            try await Task.sleep(for: .milliseconds(10))
        }

        task.cancel()

        #expect(model.look == expected)
    }

    @Test
    func watchRetriesAfterFailure() async {
        let model = AppModel(
            openDatabase: AppDatabase.inMemory,
            retryDelays: [.milliseconds(1), .milliseconds(1)]
        )

        let attempts = Attempts()
        var received: [Int] = []

        let isFailed = await model.watch(Self.values(attempts, failures: 2)) { value in
            received.append(value)
        }

        #expect(!isFailed)
        #expect(attempts.count == 3)
        #expect(received == [1])
    }

    @Test
    func watchStopsAfterRetryLimit() async {
        let model = AppModel(
            openDatabase: AppDatabase.inMemory,
            retryDelays: [.milliseconds(1)]
        )

        let attempts = Attempts()

        let isFailed = await model.watch(Self.values(attempts, failures: 10)) { _ in }

        #expect(isFailed)
        #expect(attempts.count == 2)
    }

    @Test
    func observationIDChangesWithRound() {
        let first = ObservationID(base: true, round: 0)
        let next = ObservationID(base: true, round: 1)

        #expect(first != next)
        #expect(first == ObservationID(base: true, round: 0))
        #expect(first != ObservationID(base: false, round: 0))
    }

    @Test
    func keepsObservationIDWhenNothingStopped() {
        let model = AppModel(openDatabase: AppDatabase.inMemory)
        let before = model.observationID(false)

        model.returnToForeground()

        #expect(model.observationID(false) == before)
    }

    @Test
    func changesObservationIDOnceAfterStopped() async {
        let model = AppModel(
            openDatabase: AppDatabase.inMemory,
            retryDelays: []
        )

        let before = model.observationID(false)
        let attempts = Attempts()

        await model.watch(Self.values(attempts, failures: 10)) { _ in }
        model.returnToForeground()

        let after = model.observationID(false)

        model.returnToForeground()

        #expect(after != before)
        #expect(model.observationID(false) == after)
    }

    @Test
    func detectsForegroundAfterInactive() {
        var foreground = ForegroundReturn()

        let results = [
            foreground.receive(.inactive),
            foreground.receive(.active),
            foreground.receive(.background),
            foreground.receive(.inactive),
            foreground.receive(.active),
            foreground.receive(.active)
        ]

        #expect(results == [false, false, false, false, true, false])
    }

    @Test
    func ignoresRetryUnlessFailed() async throws {
        let database = try AppDatabase.inMemory()
        let attempts = Attempts()

        let model = AppModel {
            attempts.count += 1
            return database
        }

        await model.open()
        await model.retryOpen()

        #expect(attempts.count == 1)
    }
}

extension AppModelTests {
    struct Failure: Error {}

    final class Attempts: @unchecked Sendable {
        var count = 0
    }
}

private extension AppModelTests {
    static func values(
        _ attempts: Attempts,
        failures: Int
    ) -> AsyncThrowingStream<Int, Error> {
        attempts.count += 1
        let isFailing = attempts.count <= failures

        return AsyncThrowingStream { continuation in
            if isFailing {
                continuation.finish(throwing: Failure())
            } else {
                continuation.yield(1)
                continuation.finish()
            }
        }
    }
}
