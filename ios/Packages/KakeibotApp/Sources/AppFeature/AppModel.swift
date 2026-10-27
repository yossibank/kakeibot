import Core
import Features
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
    private let retryDelays: [Duration]

    init(
        openDatabase: @escaping @Sendable () throws -> AppDatabase,
        scheduler: NotificationScheduler = NotificationScheduler(),
        router: NotificationRouter = .shared,
        retryDelays: [Duration] = ScreenObservation.retryDelays
    ) {
        self.today = Self.currentDay()
        self.openDatabase = openDatabase
        self.scheduler = scheduler
        self.router = router
        self.retryDelays = retryDelays
    }
}

extension AppModel {
    enum Launch {
        case opening
        case onboarding(AppDatabase)
        case ready(AppDatabase)
        case failed
    }

    var hasDatabase: Bool {
        switch launch {
        case .onboarding, .ready: true
        case .opening, .failed: false
        }
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
            launch = .failed
        }
    }

    func retryOpen() async {
        guard case .failed = launch else {
            return
        }

        launch = .opening

        await open()
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
            try? await database.reloadAfterOtherProcesses()
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
        await withDiscardingTaskGroup { group in
            group.addTask {
                await self.observeOverviewForWidgets(in: database)
            }

            group.addTask {
                await self.observeTemplatesForWidgets(in: database)
            }

            group.addTask {
                await self.observeTemplateOrderForWidgets(in: database)
            }
        }
    }

    func observeNotifications(in database: AppDatabase) async {
        let today = today

        await watch(database.notificationInputUpdates(from: today)) { input in
            await self.schedule(input)
        }
    }

    @discardableResult
    func watch<Values: AsyncSequence>(
        _ values: @autoclosure () -> Values,
        receive: nonisolated(nonsending) (Values.Element) async -> Void
    ) async -> Bool {
        await ScreenObservation.retry(
            values(),
            retryDelays: retryDelays,
            receive: receive
        )
    }
}

private extension AppModel {
    static func currentDay() -> LocalDate {
        LocalDate(Date(), in: .current)
    }

    func observeLook(in database: AppDatabase) async {
        await watch(database.themeLookUpdates()) { look in
            self.look = look
            self.reloadWidgets()
        }
    }

    func observeStyle(in database: AppDatabase) async {
        await watch(database.styleUpdates()) { style in
            self.style = style
            self.reloadWidgets()
        }
    }

    func observeOverviewForWidgets(in database: AppDatabase) async {
        let today = today

        await watch(database.monthOverviewUpdates(on: today)) { _ in
            self.reloadWidgets()
        }
    }

    func observeTemplatesForWidgets(in database: AppDatabase) async {
        await watch(database.templateUpdates()) { _ in
            self.reloadWidgets()
        }
    }

    func observeTemplateOrderForWidgets(in database: AppDatabase) async {
        await watch(database.settingUpdates(.templateOrder)) { _ in
            self.reloadWidgets()
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
        let plan = input.plan(today: today)
        await scheduler.apply(plan, now: Date(), timeZone: .current)
    }

    func generateRecurring(in database: AppDatabase) async {
        try? await database.generateRecurringEntries(through: today, at: Date())
    }
}
