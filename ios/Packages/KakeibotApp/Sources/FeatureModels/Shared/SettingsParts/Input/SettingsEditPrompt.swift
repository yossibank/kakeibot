public struct SettingsEditPrompt<Panel: Hashable & Sendable>: Equatable, Sendable {
    public internal(set) var panel: Panel?
    public internal(set) var togglesHiddenAfterSave = false

    private var asking: Asking?

    public init() {}
}

public extension SettingsEditPrompt {
    var isMenuOpen: Bool {
        get {
            asking == .menu
        }
        set {
            set(.menu, to: newValue)
        }
    }

    var isConfirmingDiscard: Bool {
        get {
            asking == .discard
        }
        set {
            set(.discard, to: newValue)
        }
    }

    var isConfirmingHideChanges: Bool {
        get {
            asking == .hideChanges
        }
        set {
            set(.hideChanges, to: newValue)
        }
    }

    var isConfirmingHide: Bool {
        get {
            asking == .hide
        }
        set {
            set(.hide, to: newValue)
        }
    }

    var isConfirmingDelete: Bool {
        get {
            asking == .delete
        }
        set {
            set(.delete, to: newValue)
        }
    }
}

private extension SettingsEditPrompt {
    enum Asking {
        case menu
        case discard
        case hideChanges
        case hide
        case delete
    }

    mutating func set(
        _ asking: Asking,
        to isOn: Bool
    ) {
        if isOn {
            self.asking = asking
        } else if self.asking == asking {
            self.asking = nil
        }
    }
}
