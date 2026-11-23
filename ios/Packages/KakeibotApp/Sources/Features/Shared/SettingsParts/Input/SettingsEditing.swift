import Store

@MainActor
protocol SettingsEditing: AnyObject {
    var isChanged: Bool { get }
    var isHidden: Bool { get }
    var canSave: Bool { get }

    func setHidden(_ isHidden: Bool) async -> Bool
    func delete() async -> Deletion?
}
