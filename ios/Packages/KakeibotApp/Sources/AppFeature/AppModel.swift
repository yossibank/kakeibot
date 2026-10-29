import Core
import DesignSystem
import Features
import Foundation
import Notifications
import Observation
import Store
import SwiftUI
import Sync
import WidgetKit

@MainActor
@Observable
final class AppModel {
    var notice = ErrorNotice()

    private(set) var launch: Launch = .opening
    private(set) var today: LocalDate
    private(set) var look: ThemeLook = .followsDevice
    private(set) var style: ThemeStyle = .standard
    private(set) var observationRound = 0
    private(set) var syncActivity = SyncActivity(isSyncEnabled: false, isSharing: false)

    private let openDatabase: @Sendable () throws -> AppDatabase
    private let scheduler: NotificationScheduler
    private let router: NotificationRouter
    private let shareInbox: SyncShareInbox
    private let retryDelays: [Duration]

    private var hasStoppedObservation = false
    private var syncEngine: SyncEngine?
    private var sharedSyncEngine: SyncEngine?

    init(
        openDatabase: @escaping @Sendable () throws -> AppDatabase,
        scheduler: NotificationScheduler = NotificationScheduler(),
        router: NotificationRouter = .shared,
        shareInbox: SyncShareInbox = .shared,
        retryDelays: [Duration] = ScreenObservation.retryDelays
    ) {
        self.today = Self.currentDay()
        self.openDatabase = openDatabase
        self.scheduler = scheduler
        self.router = router
        self.shareInbox = shareInbox
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

    var pendingShareCount: Int {
        shareInbox.pending.count
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

    func rescheduleNotifications() async {
        switch launch {
        case let .onboarding(database), let .ready(database):
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

    func observeSync(in database: AppDatabase) async {
        await watch(database.syncActivityUpdates()) { activity in
            self.syncActivity = activity
        }
    }

    func syncChanges(in database: AppDatabase) async {
        await syncEngine?.stop()
        await sharedSyncEngine?.stop()

        syncEngine = nil
        sharedSyncEngine = nil

        guard syncActivity.isActive else {
            return
        }

        let engine = SyncEngine(database: database, scope: .private)
        let sharedEngine = SyncEngine(database: database, scope: .shared)

        syncEngine = engine
        sharedSyncEngine = sharedEngine

        await engine.start(isSyncEnabled: syncActivity.isSyncEnabled)
        await sharedEngine.start(isSyncEnabled: syncActivity.isSyncEnabled)

        await watch(database.syncChangeUpdates()) {
            await engine.enqueuePending()
            await sharedEngine.enqueuePending()
        }
    }

    func acceptShares(in database: AppDatabase) async {
        let shares = shareInbox.take()

        guard !shares.isEmpty else {
            return
        }

        for metadata in shares {
            do {
                try await SyncEngine.acceptShare(metadata)
            } catch is CancellationError {
                continue
            } catch {
                notice.show(Self.shareFailedMessage)
            }
        }

        let engine = sharedSyncEngine ?? SyncEngine(database: database, scope: .shared)

        sharedSyncEngine = engine

        await engine.start(isSyncEnabled: syncActivity.isSyncEnabled)
        await engine.fetchChanges()
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
            retryDelays: retryDelays,
            receive: receive
        )

        if isFailed {
            hasStoppedObservation = true
        }

        return isFailed
    }
}

private extension AppModel {
    static let shareFailedMessage = "共有の口座に参加できませんでした"
    static let recurringFailedMessage = "固定費を自動で記録できませんでした"

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
        do {
            try await database.generateRecurringEntries(through: today, at: Date())
        } catch {
            notice.show(Self.recurringFailedMessage, for: error)
        }
    }
}

struct ObservationID<Base: Hashable>: Hashable {
    let base: Base
    let round: Int
}
