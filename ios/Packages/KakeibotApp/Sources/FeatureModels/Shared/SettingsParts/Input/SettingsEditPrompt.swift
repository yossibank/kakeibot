public struct SettingsEditPrompt: Equatable, Sendable {
    public var isConfirmingDiscard = false
    public var isConfirmingHideChanges = false
    public var isConfirmingDelete = false

    public internal(set) var togglesHiddenAfterSave = false

    public init() {}
}
