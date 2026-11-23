import DesignSystem
import Store

@MainActor
protocol SettingsEditModel: AnyObject {
    associatedtype Edited: Equatable
    associatedtype EditingID

    var edited: Edited { get }
    var baseline: Edited? { get }
    var editingId: EditingID? { get }
    var problemMessage: String? { get }
}

extension SettingsEditModel {
    var isEditing: Bool {
        editingId != nil
    }

    var isChanged: Bool {
        baseline.map { $0 != edited } ?? false
    }

    var canSave: Bool {
        problemMessage == nil
    }

    var saveTitle: String {
        SettingsSaveTitle.text(problem: problemMessage, isEditing: isEditing)
    }
}
