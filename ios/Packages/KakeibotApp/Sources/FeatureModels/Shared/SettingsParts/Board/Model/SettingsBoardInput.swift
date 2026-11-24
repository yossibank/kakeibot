@MainActor
public protocol SettingsBoardInput: AnyObject {
    associatedtype Snapshot

    var snapshot: Snapshot? { get }
}
