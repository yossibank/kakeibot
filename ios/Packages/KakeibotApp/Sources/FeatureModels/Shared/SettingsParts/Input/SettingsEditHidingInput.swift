@MainActor
public protocol SettingsEditHidingInput: SettingsEditInput {
    var isHidden: Bool { get }
}
