import DesignSystem
import Observation

@MainActor
@Observable
public final class SettingsBoardMovingState<ID: Sendable>: SettingsBoardState {
    public var errorNotice = ErrorNotice()

    public var movingOrder: [ID]?

    public init() {}
}
