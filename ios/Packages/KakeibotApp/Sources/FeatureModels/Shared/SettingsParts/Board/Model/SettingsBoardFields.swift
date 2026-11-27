public protocol SettingsBoardFields: ScreenEditable {
    associatedtype ID: Hashable & Sendable

    var movingOrder: [ID]? { get set }
}
