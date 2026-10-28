import Core
import DesignSystem
import Foundation
import Observation
import Store

@MainActor
@Observable
public final class ReminderModel {
    public private(set) var time: ReminderTime?
    public private(set) var authorization: NotificationAuthorization = .allowed
    public private(set) var isLoaded = false
    public private(set) var previewDay: Weekday

    public internal(set) var errorNotice = ErrorNotice()

    private var lastTime: ReminderTime = .evening
    private var input: NotificationInput?

    private let database: AppDatabase
    private let today: LocalDate
    private let permission: NotificationPermission

    public init(
        database: AppDatabase,
        today: LocalDate,
        time: ReminderTime?,
        authorization: NotificationAuthorization = .allowed,
        permission: NotificationPermission
    ) {
        self.database = database
        self.today = today
        self.time = time
        self.lastTime = time ?? .evening
        self.authorization = authorization
        self.previewDay = today.weekday
        self.permission = permission
    }
}

public extension ReminderModel {
    static let presets: [ReminderTime] = [19, 20, 21, 22, 23]
        .compactMap { ReminderTime(hour: $0, minute: 0) }

    var isOn: Bool {
        time != nil
    }

    var isDenied: Bool {
        isOn && authorization == .denied
    }

    var upcomingNotices: [PlannedNotification] {
        guard let input else {
            return []
        }

        let plan = NotificationPlan.notifications(
            today: today,
            reminderTime: time,
            recordedDates: input.recordedDates,
            recurrings: input.recurrings,
            names: input.names,
            shortages: input.shortages
        )

        let notices = plan.filter { notification in
            if case .recurring = notification.route {
                true
            } else {
                false
            }
        }

        return Array(notices.prefix(Self.noticeCount))
    }

    var isCustom: Bool {
        time.map { !Self.presets.contains($0) } ?? false
    }

    var previewMessage: ReminderMessage {
        ReminderMessage(on: previewDay)
    }

    func showPreview(on day: Weekday) {
        previewDay = day
    }

    func load() async {
        let loaded: (ReminderTime?, NotificationInput)?

        do {
            let time = try await database.setting(.reminderTime)
            let input = try await database.notificationInput(from: today)

            loaded = (time, input)
        } catch {
            loaded = nil
        }

        let authorization = await permission.authorization()

        if let (time, input) = loaded {
            self.time = time
            self.input = input
            lastTime = time ?? lastTime
        } else {
            errorNotice.show(Self.loadFailedMessage)
        }

        self.authorization = authorization
        isLoaded = true
    }

    func setOn(_ isOn: Bool) async {
        await choose(isOn ? lastTime : nil)
    }

    func choose(_ time: ReminderTime?) async {
        self.time = time
        lastTime = time ?? lastTime

        errorNotice.clear()

        do {
            try await database.setSetting(.reminderTime, to: time)
        } catch {
            errorNotice.show(Self.saveFailedMessage)
        }

        guard time != nil else {
            return
        }

        await permission.requestIfUndecided()

        authorization = await permission.authorization()
    }

    func refreshAuthorization() async {
        authorization = await permission.authorization()
    }
}

private extension ReminderModel {
    static let noticeCount = 3
    static let loadFailedMessage = "通知の設定を読めませんでした"
    static let saveFailedMessage = "通知の設定を保存できませんでした"
}
