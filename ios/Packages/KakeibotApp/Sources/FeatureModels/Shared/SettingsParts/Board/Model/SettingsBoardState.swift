import Observation

@MainActor
public protocol SettingsBoardState: NoticeHolding, Observable {
    associatedtype ID: Sendable

    var movingOrder: [ID]? { get set }
    var removed: SettingsBoardRemoved<ID> { get set }
}
