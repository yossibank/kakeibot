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
        parts: ScreenParts,
        today: LocalDate,
        time: ReminderTime?,
        authorization: NotificationAuthorization = .allowed,
        permission: NotificationPermission
    ) {
        let isCustom = time.map { !Self.presets.contains($0) } ?? false

        let state = State(
            previewDay: today.weekday,
            presented: Presented(picker: Shown(isCustom ? .timePicker : nil)),
            wait: parts.wait
        )

        let input = Input(today: today, time: time, authorization: authorization)

        self.state = state
        self.input = input
        self.output = Output(input: input, state: state)
        self.dependencies = Dependencies(database: parts.database, permission: permission)
    }
}

public extension ReminderModel {
    enum Picker: Hashable, Sendable {
        case timePicker
    }

    struct Presented: ScreenEditable {
        public var picker: Shown<Picker>
    }

    @MainActor
    @Observable
    final class State: NoticeHolding {
        public var presented: Presented

        public internal(set) var previewDay: Weekday

        public let errorNotice: ErrorNotice

        init(
            previewDay: Weekday,
            presented: Presented,
            wait: ScreenWait
        ) {
            self.errorNotice = ErrorNotice(wait: wait)
            self.previewDay = previewDay
            self.presented = presented
        }
    }

    @MainActor
    @Observable
    final class Input {
        public internal(set) var time: ReminderTime?
        public internal(set) var authorization: NotificationAuthorization

        public let hint = SettingsFoldInput.hint(.reminder)

        var lastTime: ReminderTime
        var notifications: Loadable<NotificationInput> = .loading

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
}

extension ReminderModel {
    struct Dependencies {
        let database: AppDatabase
        let permission: NotificationPermission
    }
}

public extension ReminderModel {
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
            input.notifications = .loaded(notifications)
            input.lastTime = time ?? input.lastTime
        } else {
            state.errorNotice.show(Self.loadFailedMessage)
            input.notifications = .failed
        }

        input.authorization = authorization
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

private extension ReminderModel {
    static let noticeCount = 3
    static let loadFailedMessage = "通知の設定を読めませんでした"
    static let saveFailedMessage = "通知の設定を保存できませんでした"
}

public extension ReminderModel.Output {
    var isSettled: Bool {
        input.notifications.isSettled
    }

    var isOn: Bool {
        input.time != nil
    }

    var isDenied: Bool {
        isOn && input.authorization == .denied
    }

    var upcomingNotices: [PlannedNotification] {
        guard let notifications = input.notifications.value else {
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

extension ReminderModel: SettingsFoldModel {
    public func foldStore() -> SettingsFoldStore {
        SettingsFoldStore(dependencies.database)
    }
}
