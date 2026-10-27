@testable import AppFeature
import Core
import Foundation
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
    final class Attempts: @unchecked Sendable {
        var count = 0
    }
}
