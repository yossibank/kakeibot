@MainActor
protocol SettingsBoardInput: AnyObject {
    associatedtype Snapshot

    var snapshot: Snapshot? { get set }
}
