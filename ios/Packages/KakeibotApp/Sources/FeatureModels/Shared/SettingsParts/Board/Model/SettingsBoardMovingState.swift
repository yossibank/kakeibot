import DesignSystem
import Observation

@MainActor
@Observable
public final class SettingsBoardMovingState<ID: Hashable & Sendable>: SettingsBoardState {
    public var fields = Fields()
    public var presented = SettingsBoardShown<ID, SettingsBoardDestination<ID>>()

    public let notices: SettingsBoardNotices<ID>

    public init(wait: ScreenWait) {
        self.notices = SettingsBoardNotices(wait: wait)
    }
}

public extension SettingsBoardMovingState {
    struct Fields: SettingsBoardFields {
        public var movingOrder: [ID]?
    }
}
