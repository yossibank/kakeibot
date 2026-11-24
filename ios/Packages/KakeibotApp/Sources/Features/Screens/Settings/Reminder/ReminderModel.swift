import Core
import DesignSystem
import Foundation
import Observation
import Store

@MainActor
@Observable
public final class ReminderModel {
    public let state: State
    public let input: Input
    public let output: Output

    let dependencies: Dependencies

    public init(
        database: AppDatabase,
        today: LocalDate,
        time: ReminderTime?,
        authorization: NotificationAuthorization = .allowed,
        permission: NotificationPermission
    ) {
        let state = State(previewDay: today.weekday)
        let input = Input(today: today, time: time, authorization: authorization)

        self.state = state
        self.input = input
        self.output = Output(input: input, state: state)
        self.dependencies = Dependencies(database: database, permission: permission)
    }
}

public extension ReminderModel {
    @MainActor
    @Observable
    final class State: NoticeHolding {
        public internal(set) var errorNotice = ErrorNotice()

        public internal(set) var previewDay: Weekday

        init(previewDay: Weekday) {
            self.previewDay = previewDay
        }
    }

    @MainActor
    @Observable
    final class Input {
        public internal(set) var time: ReminderTime?
        public internal(set) var authorization: NotificationAuthorization
        public internal(set) var isLoaded = false

        var lastTime: ReminderTime
        var notifications: NotificationInput?

        let today: LocalDate

        init(
            today: LocalDate,
            time: ReminderTime?,
            authorization: NotificationAuthorization
        ) {
            self.today = today
            self.time = time
            self.lastTime = time ?? .evening
            self.authorization = authorization
        }
    }

    @MainActor
    final class Output {
        let input: Input
        let state: State

        init(
            input: Input,
            state: State
        ) {
            self.input = input
            self.state = state
        }
    }

    static let presets: [ReminderTime] = [19, 20, 21, 22, 23]
        .compactMap { ReminderTime(hour: $0, minute: 0) }

    static func rowText(
        time: ReminderTime?,
        authorization: NotificationAuthorization
    ) -> String {
        guard let time else {
            return "オフ"
        }

        return authorization == .denied ? "許可が必要" : time.description
    }

    func hintFlag() -> SettingsScreenFlag {
        .closedHint(.reminder, in: dependencies.database)
    }

    func showPreview(on day: Weekday) {
        state.previewDay = day
    }

    func load() async {
        let loaded: (ReminderTime?, NotificationInput)?

        do {
            let time = try await dependencies.database.setting(.reminderTime)
            let notifications = try await dependencies.database.notificationInput(from: input.today)

            loaded = (time, notifications)
        } catch {
            loaded = nil
        }

        let authorization = await dependencies.permission.authorization()

        if let (time, notifications) = loaded {
            input.time = time
            input.notifications = notifications
            input.lastTime = time ?? input.lastTime
        } else {
            state.errorNotice.show(Self.loadFailedMessage)
        }

        input.authorization = authorization
        input.isLoaded = true
    }

    func setOn(_ isOn: Bool) async {
        await choose(isOn ? input.lastTime : nil)
    }

    func choose(_ time: ReminderTime?) async {
        input.time = time
        input.lastTime = time ?? input.lastTime

        state.errorNotice.clear()

        do {
            try await dependencies.database.setSetting(.reminderTime, to: time)
        } catch {
            state.errorNotice.show(Self.saveFailedMessage, for: error)
        }

        guard time != nil else {
            return
        }

        await dependencies.permission.requestIfUndecided()

        input.authorization = await dependencies.permission.authorization()
    }

    func refreshAuthorization() async {
        input.authorization = await dependencies.permission.authorization()
    }
}

public extension ReminderModel.Output {
    var isOn: Bool {
        input.time != nil
    }

    var isDenied: Bool {
        isOn && input.authorization == .denied
    }

    var upcomingNotices: [PlannedNotification] {
        guard let notifications = input.notifications else {
            return []
        }

        let plan = NotificationPlan.notifications(
            today: input.today,
            reminderTime: input.time,
            recordedDates: notifications.recordedDates,
            recurrings: notifications.recurrings,
            names: notifications.names,
            shortages: notifications.shortages
        )

        let notices = plan.filter { notification in
            if case .recurring = notification.route {
                true
            } else {
                false
            }
        }

        return Array(notices.prefix(ReminderModel.noticeCount))
    }

    var isCustom: Bool {
        input.time.map { !ReminderModel.presets.contains($0) } ?? false
    }

    var previewMessage: ReminderMessage {
        ReminderMessage(on: state.previewDay)
    }
}

extension ReminderModel {
    struct Dependencies {
        let database: AppDatabase
        let permission: NotificationPermission
    }
}

private extension ReminderModel {
    static let noticeCount = 3
    static let loadFailedMessage = "通知の設定を読めませんでした"
    static let saveFailedMessage = "通知の設定を保存できませんでした"
}
