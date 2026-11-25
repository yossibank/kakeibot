import Core
import FeatureModels

@MainActor
protocol SettingsEditing: AnyObject {
    associatedtype State: SettingsEditState

    var state: State { get }
    var isChanged: Bool { get }
    var isHidden: Bool { get }
    var canSave: Bool { get }

    func setHidden(_ isHidden: Bool) async -> Bool
    func delete() async -> Deletion?
}
