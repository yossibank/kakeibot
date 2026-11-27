import DesignSystem
import Observation

@MainActor
@Observable
public final class SettingsBoardMovingState<ID: Hashable & Sendable>: SettingsBoardState {
    public var presented = SettingsBoardShown<ID, SettingsBoardDestination<ID>>()

    public private(set) var movingOrder: [ID]?

    public let errorNotice: ErrorNotice
    public let removed: SettingsBoardRemoved<ID>

    public init(wait: ScreenWait) {
        self.errorNotice = ErrorNotice(wait: wait)
        self.removed = SettingsBoardRemoved(wait: wait)
    }
}

public extension SettingsBoardMovingState {
    func setMovingOrder(_ order: [ID]?) {
        movingOrder = order
    }
}
