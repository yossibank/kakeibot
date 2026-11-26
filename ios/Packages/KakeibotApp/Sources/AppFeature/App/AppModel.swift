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
    let state = State()
    let input: Input
    let dependencies: Dependencies

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

        self.input = Input(today: currentDay())

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
}

extension AppModel {
    var hasDatabase: Bool {
        state.launch.database != nil
    }

    var route: PlannedNotification.Route? {
        dependencies.router.route
    }

    var receivedShareCount: Int {
        dependencies.shareInbox.receivedCount
    }

    static func live() -> AppModel {
        AppModel(openDatabase: AppDatabase.appGroup)
    }

    func screenProStore() -> ProStore {
        dependencies.proStore
    }

    func open() async {
        guard case .opening = state.launch else {
            return
        }

        let openDatabase = dependencies.openDatabase

        do {
            let database = try await Task.detached {
                try openDatabase()
            }.value

            await generateRecurring(in: database)

            let completed = try await database.setting(.onboardingCompleted)

            input.look = await (try? database.themeLook()) ?? .followsDevice
            input.style = await (try? database.style()) ?? .standard

            let parts = ScreenParts(database: database, clock: dependencies.clock)
            let opened = Opened(database: database, parts: parts)

            state.setLaunch(completed ? .ready(opened) : .onboarding(opened))
        } catch {
            state.setLaunch(.failed)
        }
    }

    func retryOpen() async {
        guard case .failed = state.launch else {
            return
        }

        state.setLaunch(.opening)
        await open()
    }

    func open(_ url: URL) {
        dependencies.router.open(url)
    }

    func finishRoute() {
        dependencies.router.finish()
    }

    func finishOnboarding() {
        guard case let .onboarding(opened) = state.launch else {
            return
        }

        state.setLaunch(.ready(opened))
    }

    func changeScene(to phase: ScenePhase) {
        switch phase {
        case .background: AppDatabase.suspend()
        default: AppDatabase.resume()
        }

        if state.receiveScene(ForegroundReturn.Phase(phase)) {
            returnToForeground()
        }
    }

    func refreshDay() async {
        input.today = dependencies.currentDay()

        guard let database = state.launch.database else {
            return
        }

        try? await database.reloadAfterOtherProcesses()
        await generateRecurring(in: database)
        await scheduleNotifications(in: database)
    }

    func rescheduleNotifications() async {
        guard let database = state.launch.database else {
            return
        }

        await scheduleNotifications(in: database)
    }

    func observeTheme() async {
        guard let database = state.launch.database else {
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

    func observeWidgets() async {
        guard let database = state.launch.database else {
            return
        }

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

    func observeNotifications() async {
        guard let database = state.launch.database else {
            return
        }

        let today = input.today

        await watch(database.notificationInputUpdates(from: today)) { input in
            await self.schedule(input)
        }
    }

    func observeSync() async {
        guard let database = state.launch.database else {
            return
        }

        await watch(database.syncActivityUpdates()) { activity in
            self.input.syncActivity = activity
        }
    }

    func observationID<Base: Hashable>(_ base: Base) -> ObservationID<Base> {
        ObservationID(base: base, round: state.observationRound)
    }

    func returnToForeground() {
        state.restartStoppedObservation()
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
            state.markObservationStopped()
        }

        return isFailed
    }
}

private extension AppModel {
    static let widgetReloadDelay: Duration = .seconds(1)
    static let recurringFailedMessage = "固定費を自動で記録できませんでした"

    func observeLook(in database: AppDatabase) async {
        await watch(database.themeLookUpdates()) { look in
            self.input.look = look
            self.reloadWidgets()
        }
    }

    func observeStyle(in database: AppDatabase) async {
        await watch(database.styleUpdates()) { style in
            self.input.style = style
            self.reloadWidgets()
        }
    }

    func observeOverviewForWidgets(in database: AppDatabase) async {
        let today = input.today

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
        state.widgetReload?.cancel()

        state.widgetReload = Task {
            try? await Task.sleep(for: Self.widgetReloadDelay)

            guard !Task.isCancelled else {
                return
            }

            WidgetCenter.shared.reloadAllTimelines()
        }
    }

    func scheduleNotifications(in database: AppDatabase) async {
        let input = try? await database.notificationInput(from: input.today)

        guard let input else {
            return
        }

        await schedule(input)
    }

    func schedule(_ input: NotificationInput) async {
        let plan = input.plan(today: self.input.today)
        await dependencies.scheduler.apply(plan, now: dependencies.clock.now, timeZone: .current)
    }

    func generateRecurring(in database: AppDatabase) async {
        do {
            try await database.generateRecurringEntries(
                through: input.today,
                at: dependencies.clock.now
            )
        } catch {
            guard !AppDatabase.isInterrupted(error) else {
                return
            }

            state.notice.show(Self.recurringFailedMessage, for: error)
        }
    }
}
