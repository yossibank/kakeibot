import Observation

@MainActor
protocol SettingsBoardState: NoticeHolding, Observable {
    associatedtype ID: Sendable

    var movingOrder: [ID]? { get set }
}
