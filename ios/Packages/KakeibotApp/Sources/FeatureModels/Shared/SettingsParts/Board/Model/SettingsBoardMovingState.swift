import DesignSystem
import Observation

@MainActor
@Observable
public final class SettingsBoardMovingState<ID: Hashable & Sendable>: SettingsBoardState {
    public var movingOrder: [ID]?
    public var shown = SettingsBoardShown<ID, SettingsBoardDestination<ID>>()

    public let errorNotice: ErrorNotice
    public let removed: SettingsBoardRemoved<ID>

    public init(wait: ScreenWait) {
        self.errorNotice = ErrorNotice(wait: wait)
        self.removed = SettingsBoardRemoved(wait: wait)
    }
}
