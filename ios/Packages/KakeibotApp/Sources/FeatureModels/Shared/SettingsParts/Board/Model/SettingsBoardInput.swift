@MainActor
public protocol SettingsBoardInput: AnyObject {
    associatedtype Snapshot

    var snapshot: Snapshot? { get }
    var hint: SettingsFoldInput { get }
    var hiddenList: SettingsFoldInput { get }
}
