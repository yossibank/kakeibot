import Core
import Foundation
import Notifications
import Observation
import Store
import SwiftUI
import WidgetKit

@MainActor
@Observable
final class AppModel {
    private(set) var launch: Launch = .opening
    private(set) var today: LocalDate
    private(set) var look: ThemeLook = .followsDevice
    private(set) var style: ThemeStyle = .standard

    private let openDatabase: @Sendable () throws -> AppDatabase
    private let scheduler: NotificationScheduler
    private let router: NotificationRouter

    init(
        openDatabase: @escaping @Sendable () throws -> AppDatabase,
        scheduler: NotificationScheduler = NotificationScheduler(),
        router: NotificationRouter = .shared
    ) {
        self.today = Self.currentDay()
        self.openDatabase = openDatabase
        self.scheduler = scheduler
        self.router = router
    }
}

extension AppModel {
    enum Launch {
        case opening
        case onboarding(AppDatabase)
        case ready(AppDatabase)
        case failed(String)
    }

    var route: PlannedNotification.Route? {
        router.route
    }

    func open() async {
        guard case .opening = launch else {
            return
        }

        let openDatabase = openDatabase

        do {
            let database = try await Task.detached {
                try openDatabase()
            }.value

            await generateRecurring(in: database)

            let completed = try await database.setting(.onboardingCompleted)

            look = await (try? database.themeLook()) ?? .followsDevice
            style = await (try? database.style()) ?? .standard
            launch = completed ? .ready(database) : .onboarding(database)
        } catch {
            launch = .failed(String(describing: error))
        }
    }

    func open(_ url: URL) {
        router.open(url)
    }

    func finishRoute() {
        router.finish()
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
        today = Self.currentDay()

        switch launch {
        case let .onboarding(database), let .ready(database):
            await generateRecurring(in: database)
            await scheduleNotifications(in: database)
        case .opening, .failed:
            return
        }
    }

    func observeTheme() async {
        switch launch {
        case let .onboarding(database), let .ready(database):
            await withDiscardingTaskGroup { group in
                group.addTask {
                    await self.observeLook(in: database)
                }

                group.addTask {
                    await self.observeStyle(in: database)
                }
            }
        case .opening, .failed:
            return
        }
    }

    func observeWidgets(in database: AppDatabase) async {
        do {
            for try await _ in database.monthOverviewUpdates(on: today) {
                reloadWidgets()
            }
        } catch {
            return
        }
    }

    func observeNotifications(in database: AppDatabase) async {
        do {
            for try await input in database.notificationInputUpdates(
                from: today
            ) {
                await schedule(input)
            }
        } catch {
            return
        }
    }
}

private extension AppModel {
    static func currentDay() -> LocalDate {
        LocalDate(Date(), in: .current)
    }

    func observeLook(in database: AppDatabase) async {
        do {
            for try await look in database.themeLookUpdates() {
                self.look = look

                reloadWidgets()
            }
        } catch {
            return
        }
    }

    func observeStyle(in database: AppDatabase) async {
        do {
            for try await style in database.styleUpdates() {
                self.style = style
            }
        } catch {
            return
        }
    }

    func reloadWidgets() {
        WidgetCenter.shared.reloadAllTimelines()
    }

    func scheduleNotifications(in database: AppDatabase) async {
        let input = try? await database.notificationInput(from: today)

        guard let input else {
            return
        }

        await schedule(input)
    }

    func schedule(_ input: NotificationInput) async {
        let plan = NotificationPlan.notifications(
            today: today,
            reminderTime: input.reminderTime,
            recordedDates: input.recordedDates,
            recurrings: input.recurrings,
            names: input.names,
            shortages: input.shortages
        )

        await scheduler.apply(plan, now: Date(), timeZone: .current)
    }

    func generateRecurring(in database: AppDatabase) async {
        try? await database.generateRecurringEntries(through: today, at: Date())
    }
}
