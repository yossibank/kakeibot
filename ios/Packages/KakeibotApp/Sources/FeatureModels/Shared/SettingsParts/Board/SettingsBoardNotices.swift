@MainActor
public struct SettingsBoardNotices<ID: Sendable>: ScreenNotices {
    public let error: ErrorNotice
    public let removed: SettingsBoardRemoved<ID>

    public init(wait: ScreenWait) {
        self.error = ErrorNotice(wait: wait)
        self.removed = SettingsBoardRemoved(wait: wait)
    }
}
