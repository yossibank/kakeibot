import Core
import Foundation
import Notifications
import Observation
import Store
import SwiftUI

@MainActor
@Observable
final class AppModel {
    private(set) var launch: Launch = .opening

    private let openDatabase: @Sendable () throws -> AppDatabase
    private let scheduler: NotificationScheduler

    init(
        openDatabase: @escaping @Sendable () throws -> AppDatabase,
        scheduler: NotificationScheduler = NotificationScheduler()
    ) {
        self.openDatabase = openDatabase
        self.scheduler = scheduler
    }
}

extension AppModel {
    enum Launch {
        case opening
        case onboarding(AppDatabase)
        case ready(AppDatabase)
        case failed(String)
    }

    var isOpened: Bool {
        if case .opening = launch {
            false
        } else {
            true
        }
    }

    func open() async {
        guard case .opening = launch else {
            return
        }

        let openDatabase = openDatabase

        do {
            let database = try await Task.detached {
                try openDatabase()
            }
            .value

            await Self.generateRecurring(in: database)
            let completed = try await database.isOnboardingCompleted()
            launch = completed ? .ready(database) : .onboarding(database)
        } catch {
            launch = .failed(String(describing: error))
        }
    }

    func finishOnboarding() {
        guard case let .onboarding(database) = launch else {
            return
        }

        launch = .ready(database)
    }

    func changeScene(to phase: ScenePhase) {
        switch phase {
        case .background: AppDatabase.suspend()
        default: AppDatabase.resume()
        }
    }

    func refreshDay() async {
        switch launch {
        case let .onboarding(database), let .ready(database):
            await Self.generateRecurring(in: database)
            await scheduleNotifications(in: database)
        case .opening, .failed:
            return
        }
    }

    func observeNotifications(in database: AppDatabase) async {
        let start = LocalDate(Date(), in: .current)

        do {
            for try await input in database.notificationInputUpdates(
                from: start
            ) {
                await schedule(input)
            }
        } catch {
            return
        }
    }
}

private extension AppModel {
    func scheduleNotifications(in database: AppDatabase) async {
        let today = LocalDate(Date(), in: .current)

        let input = try? await database.notificationInput(from: today)

        guard let input else {
            return
        }

        await schedule(input)
    }

    func schedule(_ input: NotificationInput) async {
        let today = LocalDate(Date(), in: .current)

        let plan = NotificationPlan.notifications(
            today: today,
            reminderTime: input.reminderTime,
            recordedDates: input.recordedDates,
            recurrings: input.recurrings,
            names: input.names
        )

        await scheduler.apply(plan, now: Date(), timeZone: .current)
    }

    static func generateRecurring(in database: AppDatabase) async {
        let today = LocalDate(Date(), in: .current)
        try? await database.generateRecurringEntries(through: today, at: Date())
    }
}
