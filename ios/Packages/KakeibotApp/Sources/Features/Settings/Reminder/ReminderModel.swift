import Core
import Foundation
import Notifications
import Observation
import Store

@MainActor
@Observable
public final class ReminderModel {
    public private(set) var time: ReminderTime?
    public private(set) var authorization: NotificationAuthorization = .allowed
    public private(set) var errorMessage: String?

    private var lastTime: ReminderTime = .evening

    private let database: AppDatabase
    private let client: any NotificationCenterClient

    public init(
        database: AppDatabase,
        client: any NotificationCenterClient = LiveNotificationCenter()
    ) {
        self.database = database
        self.client = client
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

    var isCustom: Bool {
        time.map { !Self.presets.contains($0) } ?? false
    }

    func load() async {
        do {
            time = try await database.reminderTime()
            lastTime = time ?? lastTime
        } catch {
            errorMessage = Self.loadFailedMessage
        }

        authorization = await client.authorization()
    }

    func setOn(_ isOn: Bool) async {
        await choose(isOn ? lastTime : nil)
    }

    func choose(_ time: ReminderTime?) async {
        self.time = time
        lastTime = time ?? lastTime
        errorMessage = nil

        do {
            try await database.setReminderTime(time)
        } catch {
            errorMessage = Self.saveFailedMessage
        }

        guard time != nil else {
            return
        }

        if await client.authorization() == .notDetermined {
            _ = await client.requestAuthorization()
        }

        authorization = await client.authorization()
    }

    func refreshAuthorization() async {
        authorization = await client.authorization()
    }
}

private extension ReminderModel {
    static let loadFailedMessage = "通知の設定を読み込めませんでした"
    static let saveFailedMessage = "通知の設定を保存できませんでした"
}
