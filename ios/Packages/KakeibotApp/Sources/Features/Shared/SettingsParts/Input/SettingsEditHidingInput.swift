@MainActor
protocol SettingsEditHidingInput: SettingsEditInput {
    var isHidden: Bool { get }
}
