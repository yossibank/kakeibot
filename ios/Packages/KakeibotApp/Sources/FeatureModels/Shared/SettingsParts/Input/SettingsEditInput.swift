@MainActor
public protocol SettingsEditInput: AnyObject {
    associatedtype Edited: Equatable
    associatedtype EditingID

    var baseline: Edited? { get }
    var editingId: EditingID? { get }
}
