import DesignSystem
import Store

@MainActor
public protocol SettingsEditModel: ScreenPerforming {
    associatedtype State: NoticeHolding
    associatedtype Input: SettingsEditInput

    var state: State { get }
    var input: Input { get }
    var edited: Input.Edited { get }
    var problemMessage: String? { get }
}

public extension SettingsEditModel {
    var isEditing: Bool {
        input.editingId != nil
    }

    var isChanged: Bool {
        input.baseline.map { $0 != edited } ?? false
    }

    var canSave: Bool {
        problemMessage == nil
    }

    var saveTitle: String {
        SettingsSaveTitle.text(problem: problemMessage, isEditing: isEditing)
    }
}
