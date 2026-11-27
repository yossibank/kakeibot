import DesignSystem
import Observation

@MainActor
@Observable
public final class SettingsBoardMovingState<ID: Hashable & Sendable>: SettingsBoardState {
    public var presented = SettingsBoardShown<ID, SettingsBoardDestination<ID>>()

    public private(set) var movingOrder: [ID]?

    public let notices: SettingsBoardNotices<ID>

    public init(wait: ScreenWait) {
        self.notices = SettingsBoardNotices(wait: wait)
    }
}

public extension SettingsBoardMovingState {
    func setMovingOrder(_ order: [ID]?) {
        movingOrder = order
    }
}
