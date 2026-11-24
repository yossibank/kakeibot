import DesignSystem

@MainActor
protocol SettingsEditGroups: SettingsEditModel {
    associatedtype State: NoticeHolding
    associatedtype Input: SettingsEditInput where Input.Edited == Edited,
        Input.EditingID == EditingID

    var state: State { get }
    var input: Input { get }
}

extension SettingsEditGroups {
    var baseline: Edited? {
        input.baseline
    }

    var editingId: EditingID? {
        input.editingId
    }

    var errorNotice: ErrorNotice {
        get {
            state.errorNotice
        }
        set {
            state.errorNotice = newValue
        }
    }
}

extension SettingsEditGroups where Input: SettingsEditHidingInput {
    var isHidden: Bool {
        get {
            input.isHidden
        }
        set {
            input.isHidden = newValue
        }
    }
}
