import DesignSystem
import Observation

@MainActor
@Observable
public final class SettingsBoardMovingState<ID: Hashable & Sendable>: SettingsBoardState {
    public var errorNotice = ErrorNotice()

    public var movingOrder: [ID]?
    public var removed = SettingsBoardRemoved<ID>()
    public var shown = SettingsBoardShown<ID, SettingsBoardDestination<ID>>()

    public init() {}
}
