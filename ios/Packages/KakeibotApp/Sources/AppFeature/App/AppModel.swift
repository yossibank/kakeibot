import CloudKit
import Core
import DesignSystem
import FeatureModels
import Features
import Foundation
import Notifications
import Observation
import OSLog
import Store
import SwiftUI
import Sync
import WidgetKit

@MainActor
@Observable
final class AppModel: ScreenPerforming {
    var notice = ErrorNotice()
    var isPro = false
    var syncEngine: SyncEngine?
    var sharedSyncEngine: SyncEngine?

    private(set) var launch: Launch = .opening
    private(set) var today: LocalDate
    private(set) var look: ThemeLook = .followsDevice
    private(set) var style: ThemeStyle = .standard
    private(set) var observationRound = 0
    private(set) var syncActivity = SyncActivity(isSyncEnabled: false, isSharing: false)

    let dependencies: Dependencies

    private var hasStoppedObservation = false
    private var widgetReload: Task<Void, Never>?

    init(
        openDatabase: @escaping @Sendable () throws -> AppDatabase,
        scheduler: NotificationScheduler = NotificationScheduler(),
        router: NotificationRouter = .shared,
        shareInbox: SyncShareInbox = .shared,
        proStore: ProStore = .live,
        retryDelays: [Duration] = ScreenObservation.retryDelays,
        clock: ScreenClock = .system,
        currentDay: (@Sendable () -> LocalDate)? = nil
    ) {
        let currentDay = currentDay ?? {
            clock.today
        }

        self.today = currentDay()

        self.dependencies = Dependencies(
            openDatabase: openDatabase,
            clock: clock,
            currentDay: currentDay,
            scheduler: scheduler,
            router: router,
            shareInbox: shareInbox,
            proStore: proStore,
            retryDelays: retryDelays
        )
    }
}

extension AppModel {
    struct Dependencies {
        let openDatabase: @Sendable () throws -> AppDatabase
        let clock: ScreenClock
        let currentDay: @Sendable () -> LocalDate
        let scheduler: NotificationScheduler
        let router: NotificationRouter
        let shareInbox: SyncShareInbox
        let proStore: ProStore
        let retryDelays: [Duration]
    }

    func screenParts(for database: AppDatabase) -> ScreenParts {
        ScreenParts(database: database, clock: dependencies.clock)
    }

    func screenProStore() -> ProStore {
        dependencies.proStore
    }
}

extension AppModel {
    enum Launch {
        case opening
        case onboarding(AppDatabase)
        case ready(AppDatabase)
        case failed

        var database: AppDatabase? {
            switch self {
            case let .onboarding(database), let .ready(database): database
            case .opening, .failed: nil
            }
        }
    }

    var hasDatabase: Bool {
        launch.database != nil
    }

    var route: PlannedNotification.Route? {
        dependencies.router.route
    }

    var receivedShareCount: Int {
        dependencies.shareInbox.receivedCount
    }

    func open() async {
        guard case .opening = launch else {
            return
        }

        let openDatabase = dependencies.openDatabase

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
        dependencies.router.open(url)
    }

    func finishRoute() {
        dependencies.router.finish()
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
        today = dependencies.currentDay()

        guard let database = launch.database else {
            return
        }

        try? await database.reloadAfterOtherProcesses()

        await generateRecurring(in: database)
        await scheduleNotifications(in: database)
    }

    func rescheduleNotifications() async {
        guard let database = launch.database else {
            return
        }

        await scheduleNotifications(in: database)
    }

    func observeTheme() async {
        guard let database = launch.database else {
            return
        }

        await withDiscardingTaskGroup { group in
            group.addTask {
                await self.observeLook(in: database)
            }

            group.addTask {
                await self.observeStyle(in: database)
            }
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

    func observeSync(in database: AppDatabase) async {
        await watch(database.syncActivityUpdates()) { activity in
            self.syncActivity = activity
        }
    }

    func observationID<Base: Hashable>(_ base: Base) -> ObservationID<Base> {
        ObservationID(base: base, round: observationRound)
    }

    func returnToForeground() {
        guard hasStoppedObservation else {
            return
        }

        hasStoppedObservation = false
        observationRound += 1
    }

    @discardableResult
    func watch<Values: AsyncSequence>(
        _ values: @autoclosure () -> Values,
        receive: nonisolated(nonsending) (Values.Element) async -> Void
    ) async -> Bool {
        let isFailed = await ScreenObservation.retry(
            values(),
            retryDelays: dependencies.retryDelays,
            receive: receive
        )

        if isFailed {
            hasStoppedObservation = true
        }

        return isFailed
    }
}

private extension AppModel {
    static let widgetReloadDelay: Duration = .seconds(1)
    static let recurringFailedMessage = "固定費を自動で記録できませんでした"

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
        widgetReload?.cancel()

        widgetReload = Task {
            try? await Task.sleep(for: Self.widgetReloadDelay)

            guard !Task.isCancelled else {
                return
            }

            WidgetCenter.shared.reloadAllTimelines()
        }
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
        await dependencies.scheduler.apply(plan, now: dependencies.clock.now, timeZone: .current)
    }

    func generateRecurring(in database: AppDatabase) async {
        do {
            try await database.generateRecurringEntries(through: today, at: dependencies.clock.now)
        } catch {
            guard !AppDatabase.isInterrupted(error) else {
                return
            }

            notice.show(Self.recurringFailedMessage, for: error)
        }
    }
}
